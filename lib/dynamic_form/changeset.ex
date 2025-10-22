defmodule DynamicForm.Changeset do
  @moduledoc """
  Helper functions for creating dynamic changesets from DynamicForm.Instance configurations.

  This module converts a form instance into an Ecto changeset, allowing for validation
  and form handling using Phoenix's standard patterns.
  """

  alias DynamicForm.Instance

  @doc """
  Creates a changeset from a DynamicForm.Instance configuration.

  ## Parameters

    * `instance` - The DynamicForm.Instance configuration
    * `params` - The form parameters to validate (defaults to empty map)

  ## Returns

  An Ecto.Changeset that can be used with Phoenix forms.

  ## Example

      iex> instance = %DynamicForm.Instance{...}
      iex> changeset = DynamicForm.Changeset.create_changeset(instance, %{"email" => "test@example.com"})
      iex> changeset.valid?
      true
  """
  def create_changeset(%Instance{} = instance, params \\ %{}) do
    types = build_types_map(instance.fields)
    required_fields = get_required_fields(instance.fields)

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required(required_fields)
    |> apply_custom_validations(instance.fields)
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
  defp map_field_type(type) when is_binary(type), do: String.to_atom(type)
  defp map_field_type(type) when is_atom(type), do: type

  defp get_required_fields(fields) do
    fields
    |> Enum.filter(& &1.required)
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
