defmodule DynamicForm.Changeset do
  @moduledoc """
  Helper functions for creating dynamic changesets from DynamicForm.Instance configurations.

  This module converts a form instance into an Ecto changeset, allowing for validation
  and form handling using Phoenix's standard patterns.
  """

  alias DynamicForm.Instance

  @doc """
  Creates a changeset from a DynamicForm.Instance configuration.

  Only form fields are included in the changeset. Elements (headings, paragraphs, etc.)
  are filtered out as they don't collect user input.

  ## Parameters

    * `instance` - The DynamicForm.Instance struct
    * `params` - The form parameters to validate (defaults to empty map)

  ## Returns

  An Ecto.Changeset that can be used with Phoenix forms.

  ## Example

      iex> instance = %DynamicForm.Instance{...}
      iex> changeset = DynamicForm.Changeset.create_changeset(instance, %{"email" => "test@example.com"})
      iex> changeset.valid?
      true

  ## Note

  If you have JSON or a map, decode it to an Instance struct first:

      # Decode at the edge
      instance = DynamicForm.Instance.decode!(json_or_map)
      changeset = DynamicForm.Changeset.create_changeset(instance, params)
  """
  def create_changeset(%Instance{} = instance, params \\ %{}) do
    fields = get_fields(instance.items)
    types = build_types_map(fields)
    required_fields = get_required_fields(fields, params)

    # Decode JSON-encoded direct_upload fields
    decoded_params = decode_upload_params(params, fields)

    {%{}, types}
    |> Ecto.Changeset.cast(decoded_params, Map.keys(types), empty_values: [])
    |> Ecto.Changeset.validate_required(required_fields)
    |> apply_custom_validations(fields)
  end

  @doc """
  Extracts only Field structs from the items list, filtering out Elements.

  Recursively extracts fields from group elements that contain nested items.

  ## Example

      iex> items = [
      ...>   %DynamicForm.Instance.Element{id: "h1", type: "heading"},
      ...>   %DynamicForm.Instance.Field{id: "email", name: "email", type: "email"},
      ...>   %DynamicForm.Instance.Element{
      ...>     id: "group-1",
      ...>     type: "group",
      ...>     items: [
      ...>       %DynamicForm.Instance.Field{id: "city", name: "city", type: "string"}
      ...>     ]
      ...>   }
      ...> ]
      iex> DynamicForm.Changeset.get_fields(items)
      [
        %DynamicForm.Instance.Field{id: "email", name: "email", type: "email"},
        %DynamicForm.Instance.Field{id: "city", name: "city", type: "string"}
      ]
  """
  def get_fields(items) when is_list(items) do
    Enum.flat_map(items, fn item ->
      case item do
        %Instance.Field{} = field ->
          [field]

        %Instance.Element{items: nested_items} when is_list(nested_items) ->
          get_fields(nested_items)

        %Instance.Element{} ->
          []
      end
    end)
  end

  @doc """
  Builds a map of field names to their Ecto types.

  ## Example

      iex> fields = [
      ...>   %DynamicForm.Instance.Field{id: "1", name: "email", type: "string"},
      ...>   %DynamicForm.Instance.Field{id: "2", name: "age", type: "decimal"}
      ...> ]
      iex> DynamicForm.Changeset.build_types_map(fields)
      %{email: :string, age: :decimal}
  """
  def build_types_map(fields) when is_list(fields) do
    Enum.reduce(fields, %{}, fn field, acc ->
      # Convert field name to atom for Ecto
      field_atom = String.to_atom(field.name)
      Map.put(acc, field_atom, map_field_type(field.type))
    end)
  end

  # Maps DynamicForm field types (strings) to Ecto types (atoms)
  defp map_field_type("string"), do: :string
  defp map_field_type("email"), do: :string
  defp map_field_type("textarea"), do: :string
  defp map_field_type("decimal"), do: :decimal
  defp map_field_type("boolean"), do: :boolean
  defp map_field_type("select"), do: :string
  defp map_field_type("radio"), do: :string
  defp map_field_type("radio-group"), do: :string
  defp map_field_type("direct_upload"), do: {:array, :map}
  defp map_field_type(type) when is_binary(type), do: String.to_atom(type)
  defp map_field_type(type) when is_atom(type), do: type

  defp decode_upload_params(params, fields) do
    upload_fields =
      fields
      |> Enum.filter(&(&1.type == "direct_upload"))
      |> Enum.map(& &1.name)

    Enum.reduce(upload_fields, params, fn field_name, acc ->
      case Map.get(acc, field_name) do
        value when is_binary(value) ->
          # Decode JSON string to list of maps
          case Jason.decode(value) do
            {:ok, decoded} -> Map.put(acc, field_name, decoded)
            {:error, _} -> acc
          end

        # Already decoded or nil
        _ ->
          acc
      end
    end)
  end

  defp get_required_fields(fields, params) do
    fields
    |> Enum.filter(fn field ->
      field.required && DynamicForm.Visibility.field_visible?(field, params)
    end)
    |> Enum.map(&String.to_atom(&1.name))
  end

  defp apply_custom_validations(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, acc ->
      apply_field_validations(acc, field)
    end)
  end

  defp apply_field_validations(changeset, field) do
    validations = field.validations || []
    field_atom = String.to_atom(field.name)

    Enum.reduce(validations, changeset, fn validation, acc ->
      apply_validation(acc, field_atom, validation)
    end)
  end

  # Apply specific validation types (string-based)
  defp apply_validation(changeset, field_name, %Instance.Validation{
         type: "min_length",
         value: min
       }) do
    Ecto.Changeset.validate_length(changeset, field_name, min: min)
  end

  defp apply_validation(changeset, field_name, %Instance.Validation{
         type: "max_length",
         value: max
       }) do
    Ecto.Changeset.validate_length(changeset, field_name, max: max)
  end

  defp apply_validation(changeset, field_name, %Instance.Validation{type: "email_format"}) do
    Ecto.Changeset.validate_format(changeset, field_name, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
  end

  defp apply_validation(changeset, field_name, %Instance.Validation{
         type: "numeric_range",
         min: min,
         max: max
       }) do
    changeset
    |> Ecto.Changeset.validate_number(field_name, greater_than_or_equal_to: min)
    |> Ecto.Changeset.validate_number(field_name, less_than_or_equal_to: max)
  end

  # Fallback for unknown validation types
  defp apply_validation(changeset, _field_name, _validation) do
    changeset
  end
end
