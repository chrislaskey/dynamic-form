defmodule DynamicForm.Visibility do
  @moduledoc false
  # Internal module for evaluating field visibility conditions.
  #
  # This module determines whether a field should be visible based on its
  # `visible_when` conditions and the current form parameter values.

  alias DynamicForm.Instance

  @doc """
  Determines if a field is visible based on its visible_when conditions and current params.

  ## Parameters

    * `field` - An `Instance.Field` struct
    * `params` - Map of current form values (string or atom keys)

  ## Returns

    * `true` - Field is visible (no conditions or all conditions evaluate to true)
    * `false` - Field is hidden (has conditions that evaluate to false)

  ## Examples

      # Field with no visible_when - always visible
      field = %Instance.Field{name: "email", visible_when: nil}
      Visibility.field_visible?(field, %{}) #=> true

      # Field with equals condition - visible when payment_method is "credit_card"
      field = %Instance.Field{
        name: "card_number",
        visible_when: %{field: "payment_method", operator: "equals", value: "credit_card"}
      }
      Visibility.field_visible?(field, %{"payment_method" => "credit_card"}) #=> true
      Visibility.field_visible?(field, %{"payment_method" => "paypal"}) #=> false

      # Field with valid condition - visible when email has a valid value
      field = %Instance.Field{
        name: "confirm_email",
        visible_when: %{field: "email", operator: "valid"}
      }
      Visibility.field_visible?(field, %{"email" => "user@example.com"}) #=> true
      Visibility.field_visible?(field, %{"email" => ""}) #=> false
  """
  def field_visible?(%Instance.Field{visible_when: nil}, _params), do: true
  def field_visible?(%Instance.Field{visible_when: []}, _params), do: true

  def field_visible?(%Instance.Field{visible_when: conditions}, params) when is_list(conditions) do
    Enum.all?(conditions, &evaluate_condition(&1, params))
  end

  def field_visible?(%Instance.Field{visible_when: condition}, params) when is_map(condition) do
    evaluate_condition(condition, params)
  end

  @doc """
  Evaluates a single visible_when condition against the current params.

  ## Supported Operators

    * `"equals"` - Field value must exactly match the expected value
    * `"valid"` - Field must have a non-empty value

  ## Parameters

    * `condition` - Map with `field`, `operator`, and optionally `value` keys (atom or string keys)
    * `params` - Map of current form values (string or atom keys)

  ## Returns

    * `true` - Condition evaluates to true
    * `false` - Condition evaluates to false or evaluation fails
  """
  def evaluate_condition(%{field: field_name, operator: "equals", value: expected}, params) do
    current_value = get_field_value(params, field_name)
    current_value == expected
  rescue
    _ -> false
  end

  def evaluate_condition(
        %{"field" => field_name, "operator" => "equals", "value" => expected},
        params
      ) do
    current_value = get_field_value(params, field_name)
    current_value == expected
  rescue
    _ -> false
  end

  def evaluate_condition(%{field: field_name, operator: "valid"}, params) do
    current_value = get_field_value(params, field_name)
    has_value?(current_value)
  rescue
    _ -> false
  end

  def evaluate_condition(%{"field" => field_name, "operator" => "valid"}, params) do
    current_value = get_field_value(params, field_name)
    has_value?(current_value)
  rescue
    _ -> false
  end

  # Fallback for unknown operators or malformed conditions
  def evaluate_condition(_condition, _params), do: false

  # Helper to get field value from params, handling both string and atom keys
  defp get_field_value(params, field_name) when is_binary(field_name) do
    Map.get(params, field_name) || Map.get(params, String.to_existing_atom(field_name))
  rescue
    ArgumentError -> Map.get(params, field_name)
  end

  defp get_field_value(params, field_name) when is_atom(field_name) do
    Map.get(params, field_name) || Map.get(params, Atom.to_string(field_name))
  end

  # Helper to check if a value is considered "present"
  defp has_value?(nil), do: false
  defp has_value?(""), do: false
  defp has_value?(_), do: true
end
