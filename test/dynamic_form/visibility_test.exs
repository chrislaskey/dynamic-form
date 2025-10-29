defmodule DynamicForm.VisibilityTest do
  use ExUnit.Case, async: true

  alias DynamicForm.{Visibility, Instance}

  describe "field_visible?/2 - fields without visible_when" do
    test "returns true when visible_when is nil" do
      field = %Instance.Field{
        id: "email",
        name: "email",
        type: "email",
        label: "Email",
        required: true,
        visible_when: nil
      }

      assert Visibility.field_visible?(field, %{})
      assert Visibility.field_visible?(field, %{"other_field" => "value"})
    end

    test "returns true when visible_when is empty list" do
      field = %Instance.Field{
        id: "email",
        name: "email",
        type: "email",
        label: "Email",
        required: true,
        visible_when: []
      }

      assert Visibility.field_visible?(field, %{})
    end
  end

  describe "field_visible?/2 - equals operator with atom keys" do
    setup do
      field = %Instance.Field{
        id: "card_number",
        name: "card_number",
        type: "string",
        label: "Card Number",
        required: true,
        visible_when: %{field: "payment_method", operator: "equals", value: "credit_card"}
      }

      {:ok, field: field}
    end

    test "returns true when condition matches", %{field: field} do
      params = %{"payment_method" => "credit_card"}
      assert Visibility.field_visible?(field, params)
    end

    test "returns false when condition does not match", %{field: field} do
      params = %{"payment_method" => "paypal"}
      refute Visibility.field_visible?(field, params)
    end

    test "returns false when field is missing from params", %{field: field} do
      params = %{}
      refute Visibility.field_visible?(field, params)
    end

    test "returns false when field value is nil", %{field: field} do
      params = %{"payment_method" => nil}
      refute Visibility.field_visible?(field, params)
    end

    test "handles atom keys in params", %{field: field} do
      params = %{payment_method: "credit_card"}
      assert Visibility.field_visible?(field, params)
    end
  end

  describe "field_visible?/2 - equals operator with string keys" do
    setup do
      field = %Instance.Field{
        id: "card_number",
        name: "card_number",
        type: "string",
        label: "Card Number",
        required: true,
        visible_when: %{
          "field" => "payment_method",
          "operator" => "equals",
          "value" => "credit_card"
        }
      }

      {:ok, field: field}
    end

    test "returns true when condition matches", %{field: field} do
      params = %{"payment_method" => "credit_card"}
      assert Visibility.field_visible?(field, params)
    end

    test "returns false when condition does not match", %{field: field} do
      params = %{"payment_method" => "paypal"}
      refute Visibility.field_visible?(field, params)
    end

    test "handles atom keys in params", %{field: field} do
      params = %{payment_method: "credit_card"}
      assert Visibility.field_visible?(field, params)
    end
  end

  describe "field_visible?/2 - valid operator with atom keys" do
    setup do
      field = %Instance.Field{
        id: "confirm_email",
        name: "confirm_email",
        type: "email",
        label: "Confirm Email",
        required: true,
        visible_when: %{field: "email", operator: "valid"}
      }

      {:ok, field: field}
    end

    test "returns true when field has a non-empty value", %{field: field} do
      params = %{"email" => "user@example.com"}
      assert Visibility.field_visible?(field, params)
    end

    test "returns false when field value is nil", %{field: field} do
      params = %{"email" => nil}
      refute Visibility.field_visible?(field, params)
    end

    test "returns false when field value is empty string", %{field: field} do
      params = %{"email" => ""}
      refute Visibility.field_visible?(field, params)
    end

    test "returns false when field is missing from params", %{field: field} do
      params = %{}
      refute Visibility.field_visible?(field, params)
    end

    test "handles atom keys in params", %{field: field} do
      params = %{email: "user@example.com"}
      assert Visibility.field_visible?(field, params)
    end

    test "returns true for numeric values", %{field: field} do
      # Update to use a numeric field for this test
      field = %{field | visible_when: %{field: "age", operator: "valid"}}
      params = %{"age" => 25}
      assert Visibility.field_visible?(field, params)
    end

    test "returns true for boolean false value", %{field: field} do
      field = %{field | visible_when: %{field: "agree", operator: "valid"}}
      params = %{"agree" => false}
      assert Visibility.field_visible?(field, params)
    end
  end

  describe "field_visible?/2 - valid operator with string keys" do
    setup do
      field = %Instance.Field{
        id: "confirm_email",
        name: "confirm_email",
        type: "email",
        label: "Confirm Email",
        required: true,
        visible_when: %{"field" => "email", "operator" => "valid"}
      }

      {:ok, field: field}
    end

    test "returns true when field has a non-empty value", %{field: field} do
      params = %{"email" => "user@example.com"}
      assert Visibility.field_visible?(field, params)
    end

    test "returns false when field value is empty", %{field: field} do
      params = %{"email" => ""}
      refute Visibility.field_visible?(field, params)
    end

    test "handles atom keys in params", %{field: field} do
      params = %{email: "user@example.com"}
      assert Visibility.field_visible?(field, params)
    end
  end

  describe "field_visible?/2 - multiple conditions (AND logic)" do
    test "returns true when all conditions match" do
      field = %Instance.Field{
        id: "international_phone",
        name: "international_phone",
        type: "string",
        label: "International Phone",
        required: true,
        visible_when: [
          %{field: "country", operator: "equals", value: "international"},
          %{field: "has_phone", operator: "equals", value: true}
        ]
      }

      params = %{"country" => "international", "has_phone" => true}
      assert Visibility.field_visible?(field, params)
    end

    test "returns false when one condition does not match" do
      field = %Instance.Field{
        id: "international_phone",
        name: "international_phone",
        type: "string",
        label: "International Phone",
        required: true,
        visible_when: [
          %{field: "country", operator: "equals", value: "international"},
          %{field: "has_phone", operator: "equals", value: true}
        ]
      }

      params = %{"country" => "international", "has_phone" => false}
      refute Visibility.field_visible?(field, params)
    end

    test "returns false when all conditions do not match" do
      field = %Instance.Field{
        id: "international_phone",
        name: "international_phone",
        type: "string",
        label: "International Phone",
        required: true,
        visible_when: [
          %{field: "country", operator: "equals", value: "international"},
          %{field: "has_phone", operator: "equals", value: true}
        ]
      }

      params = %{"country" => "domestic", "has_phone" => false}
      refute Visibility.field_visible?(field, params)
    end
  end

  describe "field_visible?/2 - edge cases" do
    test "handles non-existent field in condition gracefully" do
      field = %Instance.Field{
        id: "conditional",
        name: "conditional",
        type: "string",
        label: "Conditional",
        visible_when: %{field: "non_existent_field", operator: "equals", value: "value"}
      }

      params = %{"other_field" => "value"}
      refute Visibility.field_visible?(field, params)
    end

    test "handles malformed condition gracefully" do
      field = %Instance.Field{
        id: "conditional",
        name: "conditional",
        type: "string",
        label: "Conditional",
        visible_when: %{invalid: "condition"}
      }

      params = %{"field" => "value"}
      refute Visibility.field_visible?(field, params)
    end

    test "handles mixed string and atom keys in params" do
      field = %Instance.Field{
        id: "conditional",
        name: "conditional",
        type: "string",
        label: "Conditional",
        visible_when: %{field: "payment_method", operator: "equals", value: "credit_card"}
      }

      # String key in condition, atom key in params
      params = %{"other" => "value", payment_method: "credit_card"}
      assert Visibility.field_visible?(field, params)
    end
  end

  describe "evaluate_condition/2" do
    test "returns false for unknown operator" do
      condition = %{field: "test", operator: "unknown", value: "value"}
      params = %{"test" => "value"}
      refute Visibility.evaluate_condition(condition, params)
    end

    test "returns false for nil condition" do
      refute Visibility.evaluate_condition(nil, %{})
    end
  end
end
