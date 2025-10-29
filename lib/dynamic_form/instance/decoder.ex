defmodule DynamicForm.Instance.Decoder do
  @moduledoc """
  Decodes JSON data or maps into DynamicForm.Instance structs.

  This module handles the conversion of JSON-encoded form configurations
  back into proper Elixir structs, including nested items and special
  types like module atoms and DateTime values.

  ## Examples

      iex> json = ~s({"id": "my-form", "name": "My Form", "items": []})
      iex> map = Jason.decode!(json)
      iex> DynamicForm.Instance.Decoder.decode_instance(map)
      %DynamicForm.Instance{id: "my-form", name: "My Form", items: []}
  """

  alias DynamicForm.Instance

  @doc """
  Decodes a map into a DynamicForm.Instance struct.
  """
  def decode_instance(data) when is_map(data) do
    %Instance{
      id: Map.fetch!(data, "id"),
      name: Map.get(data, "name"),
      description: Map.get(data, "description"),
      items: decode_items(Map.get(data, "items", [])),
      backend: decode_backend(Map.get(data, "backend")),
      metadata: Map.get(data, "metadata"),
      inserted_at: decode_datetime(Map.get(data, "inserted_at")),
      updated_at: decode_datetime(Map.get(data, "updated_at"))
    }
  end

  @doc """
  Decodes a list of items (fields and elements).
  """
  def decode_items(items) when is_list(items) do
    Enum.map(items, &decode_item/1)
  end

  def decode_items(nil), do: []

  @doc """
  Decodes a single item (field or element) based on its __type__ field.
  """
  def decode_item(%{"__type__" => "Field"} = data), do: decode_field(data)
  def decode_item(%{"__type__" => "Element"} = data), do: decode_element(data)

  # Fallback: try to infer type based on presence of "name" field
  def decode_item(%{"name" => _} = data), do: decode_field(data)
  def decode_item(data), do: decode_element(data)

  @doc """
  Decodes a field map into an Instance.Field struct.
  """
  def decode_field(data) when is_map(data) do
    %Instance.Field{
      id: Map.fetch!(data, "id"),
      name: Map.fetch!(data, "name"),
      type: Map.fetch!(data, "type"),
      label: Map.get(data, "label"),
      placeholder: Map.get(data, "placeholder"),
      help_text: Map.get(data, "help_text"),
      default_value: Map.get(data, "default_value"),
      options: decode_options(Map.get(data, "options")),
      validations: decode_validations(Map.get(data, "validations")),
      required: Map.get(data, "required"),
      disabled: Map.get(data, "disabled"),
      visible_when: decode_visible_when(Map.get(data, "visible_when")),
      metadata: Map.get(data, "metadata")
    }
  end

  @doc """
  Decodes an element map into an Instance.Element struct.
  """
  def decode_element(data) when is_map(data) do
    %Instance.Element{
      id: Map.fetch!(data, "id"),
      type: Map.fetch!(data, "type"),
      content: Map.get(data, "content"),
      items: decode_items(Map.get(data, "items")),
      visible_when: decode_visible_when(Map.get(data, "visible_when")),
      metadata: Map.get(data, "metadata")
    }
  end

  @doc """
  Decodes a backend map into an Instance.Backend struct.
  """
  def decode_backend(nil), do: nil

  def decode_backend(data) when is_map(data) do
    %Instance.Backend{
      module: decode_module(Map.fetch!(data, "module")),
      function: decode_atom(Map.fetch!(data, "function")),
      config: decode_config(Map.get(data, "config", [])),
      name: Map.get(data, "name"),
      description: Map.get(data, "description")
    }
  end

  @doc """
  Decodes a validation list.
  """
  def decode_validations(nil), do: nil
  def decode_validations([]), do: []

  def decode_validations(validations) when is_list(validations) do
    Enum.map(validations, &decode_validation/1)
  end

  @doc """
  Decodes a single validation map into an Instance.Validation struct.
  """
  def decode_validation(data) when is_map(data) do
    %Instance.Validation{
      type: Map.fetch!(data, "type"),
      value: Map.get(data, "value"),
      min: Map.get(data, "min"),
      max: Map.get(data, "max"),
      message: Map.get(data, "message")
    }
  end

  @doc """
  Decodes field options.

  Options can be:
  - A list of strings: ["option1", "option2"]
  - A list of tuples (encoded as lists): [["Label", "value"], ["Label 2", "value2"]]
  """
  def decode_options(nil), do: nil
  def decode_options([]), do: []

  def decode_options(options) when is_list(options) do
    Enum.map(options, fn
      # Two-element list represents a tuple {label, value}
      [label, value] when is_binary(label) and is_binary(value) ->
        {label, value}

      # Single string option
      value when is_binary(value) ->
        value

      # Already a map with label/value
      %{"label" => label, "value" => value} ->
        {label, value}

      # Fallback
      other ->
        other
    end)
  end

  @doc """
  Decodes a visible_when condition map.
  """
  def decode_visible_when(nil), do: nil

  def decode_visible_when(data) when is_map(data) do
    # Return as plain map with string keys (already the right format)
    %{
      "field" => Map.fetch!(data, "field"),
      "operator" => Map.fetch!(data, "operator"),
      "value" => Map.get(data, "value")
    }
  end

  @doc """
  Decodes a module name string into a module atom.

  Only converts to atom if the module is already loaded to prevent
  atom exhaustion attacks.
  """
  def decode_module(module_string) when is_binary(module_string) do
    # Convert string like "Elixir.MyApp.Backend" or "MyApp.Backend" to atom
    module_string = ensure_elixir_prefix(module_string)

    # Only convert to existing atoms to prevent atom exhaustion
    String.to_existing_atom(module_string)
  rescue
    ArgumentError ->
      raise ArgumentError,
            "Module #{module_string} is not loaded. " <>
              "Please ensure the module is loaded before decoding."
  end

  def decode_module(module) when is_atom(module), do: module

  @doc """
  Decodes an atom from a string.

  Only converts to atom if it already exists to prevent atom exhaustion.
  """
  def decode_atom(string) when is_binary(string) do
    String.to_existing_atom(string)
  rescue
    ArgumentError ->
      raise ArgumentError, "Atom :#{string} does not exist. Cannot decode safely."
  end

  def decode_atom(atom) when is_atom(atom), do: atom

  @doc """
  Decodes backend config.

  Config can be a keyword list or a map. We convert maps to keyword lists.
  """
  def decode_config(nil), do: []
  def decode_config([]), do: []

  def decode_config(config) when is_map(config) do
    Enum.map(config, fn {key, value} ->
      {decode_atom(key), value}
    end)
  end

  def decode_config(config) when is_list(config) do
    # Could be a keyword list already or a list of maps
    Enum.map(config, fn
      %{"key" => key, "value" => value} ->
        {decode_atom(key), value}

      {key, value} when is_atom(key) ->
        {key, value}

      {key, value} when is_binary(key) ->
        {decode_atom(key), value}

      [key, value] when is_binary(key) ->
        {decode_atom(key), value}
    end)
  end

  @doc """
  Decodes a DateTime from an ISO8601 string.
  """
  def decode_datetime(nil), do: nil

  def decode_datetime(string) when is_binary(string) do
    case DateTime.from_iso8601(string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  def decode_datetime(%DateTime{} = dt), do: dt

  # Private helpers

  defp ensure_elixir_prefix("Elixir." <> _ = module_string), do: module_string
  defp ensure_elixir_prefix(module_string), do: "Elixir." <> module_string
end
