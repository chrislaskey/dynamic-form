defmodule DynamicForm.ChangesetConditionalRequiredTest do
  use ExUnit.Case, async: true

  alias DynamicForm.{Instance, Changeset}

  describe "conditional required validation - equals operator" do
    setup do
      # Form with payment method selection and conditional credit card field
      instance = %Instance{
        id: "payment-form",
        items: [
          %Instance.Field{
            id: "payment_method",
            name: "payment_method",
            type: "select",
            label: "Payment Method",
            required: true,
            options: [
              %{"label" => "Credit Card", "value" => "credit_card"},
              %{"label" => "PayPal", "value" => "paypal"}
            ]
          },
          %Instance.Field{
            id: "card_number",
            name: "card_number",
            type: "string",
            label: "Card Number",
            required: true,
            visible_when: %{field: "payment_method", operator: "equals", value: "credit_card"}
          }
        ]
      }

      {:ok, instance: instance}
    end

    test "validates required field when condition is met", %{instance: instance} do
      # Payment method is credit_card, so card_number should be required
      params = %{"payment_method" => "credit_card"}
      changeset = Changeset.create_changeset(instance, params)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:card_number]
    end

    test "does not validate required field when condition is not met", %{instance: instance} do
      # Payment method is paypal, so card_number should NOT be required
      params = %{"payment_method" => "paypal"}
      changeset = Changeset.create_changeset(instance, params)

      assert changeset.valid?
      refute Keyword.has_key?(changeset.errors, :card_number)
    end

    test "validates successfully when visible required field has value", %{instance: instance} do
      params = %{"payment_method" => "credit_card", "card_number" => "4111111111111111"}
      changeset = Changeset.create_changeset(instance, params)

      assert changeset.valid?
    end

    test "validates successfully when hidden required field is empty", %{instance: instance} do
      params = %{"payment_method" => "paypal", "card_number" => ""}
      changeset = Changeset.create_changeset(instance, params)

      assert changeset.valid?
    end
  end

  describe "conditional required validation - valid operator" do
    setup do
      instance = %Instance{
        id: "registration-form",
        items: [
          %Instance.Field{
            id: "email",
            name: "email",
            type: "email",
            label: "Email",
            required: true
          },
          %Instance.Field{
            id: "confirm_email",
            name: "confirm_email",
            type: "email",
            label: "Confirm Email",
            required: true,
            visible_when: %{field: "email", operator: "valid"}
          }
        ]
      }

      {:ok, instance: instance}
    end

    test "validates required field when condition is met (email has value)", %{instance: instance} do
      params = %{"email" => "user@example.com"}
      changeset = Changeset.create_changeset(instance, params)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:confirm_email]
    end

    test "does not validate required field when condition is not met (email empty)", %{
      instance: instance
    } do
      params = %{"email" => ""}
      changeset = Changeset.create_changeset(instance, params)

      # Email is required, so validation should fail for email, not confirm_email
      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:email]
      refute Keyword.has_key?(changeset.errors, :confirm_email)
    end

    test "validates successfully when both fields have values", %{instance: instance} do
      params = %{"email" => "user@example.com", "confirm_email" => "user@example.com"}
      changeset = Changeset.create_changeset(instance, params)

      assert changeset.valid?
    end
  end

  describe "conditional required validation - nested fields" do
    test "validates conditional required field in section" do
      instance = %Instance{
        id: "profile-form",
        items: [
          %Instance.Element{
            id: "address-section",
            type: "section",
            content: "Address",
            items: [
              %Instance.Field{
                id: "country",
                name: "country",
                type: "select",
                label: "Country",
                required: true,
                options: [
                  %{"label" => "USA", "value" => "usa"},
                  %{"label" => "International", "value" => "international"}
                ]
              },
              %Instance.Field{
                id: "international_phone",
                name: "international_phone",
                type: "string",
                label: "International Phone",
                required: true,
                visible_when: %{field: "country", operator: "equals", value: "international"}
              }
            ]
          }
        ]
      }

      # International selected - phone should be required
      params = %{"country" => "international"}
      changeset = Changeset.create_changeset(instance, params)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:international_phone]

      # USA selected - phone should NOT be required
      params = %{"country" => "usa"}
      changeset = Changeset.create_changeset(instance, params)

      assert changeset.valid?
    end

    test "validates conditional required field in group" do
      instance = %Instance{
        id: "contact-form",
        items: [
          %Instance.Element{
            id: "contact-group",
            type: "group",
            items: [
              %Instance.Field{
                id: "has_phone",
                name: "has_phone",
                type: "boolean",
                label: "I have a phone",
                required: false
              },
              %Instance.Field{
                id: "phone",
                name: "phone",
                type: "string",
                label: "Phone Number",
                required: true,
                visible_when: %{field: "has_phone", operator: "equals", value: true}
              }
            ]
          }
        ]
      }

      # has_phone is true - phone should be required
      params = %{"has_phone" => true}
      changeset = Changeset.create_changeset(instance, params)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:phone]

      # has_phone is false - phone should NOT be required
      params = %{"has_phone" => false}
      changeset = Changeset.create_changeset(instance, params)

      assert changeset.valid?
    end
  end

  describe "conditional required validation - multiple conditions" do
    test "validates required field when all conditions are met (AND logic)" do
      instance = %Instance{
        id: "complex-form",
        items: [
          %Instance.Field{
            id: "has_business",
            name: "has_business",
            type: "boolean",
            label: "I have a business",
            required: false
          },
          %Instance.Field{
            id: "business_type",
            name: "business_type",
            type: "select",
            label: "Business Type",
            required: false,
            options: [
              %{"label" => "Corporation", "value" => "corp"},
              %{"label" => "LLC", "value" => "llc"}
            ]
          },
          %Instance.Field{
            id: "ein",
            name: "ein",
            type: "string",
            label: "EIN",
            required: true,
            visible_when: [
              %{field: "has_business", operator: "equals", value: true},
              %{field: "business_type", operator: "equals", value: "corp"}
            ]
          }
        ]
      }

      # Both conditions met - EIN required
      params = %{"has_business" => true, "business_type" => "corp"}
      changeset = Changeset.create_changeset(instance, params)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:ein]

      # Only one condition met - EIN NOT required
      params = %{"has_business" => true, "business_type" => "llc"}
      changeset = Changeset.create_changeset(instance, params)

      assert changeset.valid?

      # Neither condition met - EIN NOT required
      params = %{"has_business" => false, "business_type" => ""}
      changeset = Changeset.create_changeset(instance, params)

      assert changeset.valid?
    end
  end

  describe "conditional required validation - always required fields" do
    test "validates fields without visible_when as always required" do
      instance = %Instance{
        id: "mixed-form",
        items: [
          %Instance.Field{
            id: "name",
            name: "name",
            type: "string",
            label: "Name",
            required: true
            # No visible_when - always required
          },
          %Instance.Field{
            id: "category",
            name: "category",
            type: "select",
            label: "Category",
            required: false,
            options: [
              %{"label" => "A", "value" => "a"},
              %{"label" => "B", "value" => "b"}
            ]
          },
          %Instance.Field{
            id: "details",
            name: "details",
            type: "string",
            label: "Details",
            required: true,
            visible_when: %{field: "category", operator: "equals", value: "a"}
          }
        ]
      }

      # Name should always be required regardless of category
      params = %{"category" => "b"}
      changeset = Changeset.create_changeset(instance, params)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:name]
      refute Keyword.has_key?(changeset.errors, :details)

      # When category is "a", both name and details are required
      params = %{"category" => "a"}
      changeset = Changeset.create_changeset(instance, params)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:name]
      assert {"can't be blank", _} = changeset.errors[:details]
    end
  end

  describe "conditional required validation - optional fields" do
    test "does not validate optional fields even when visible" do
      instance = %Instance{
        id: "optional-form",
        items: [
          %Instance.Field{
            id: "has_notes",
            name: "has_notes",
            type: "boolean",
            label: "Add notes?",
            required: false
          },
          %Instance.Field{
            id: "notes",
            name: "notes",
            type: "textarea",
            label: "Notes",
            required: false,  # Optional
            visible_when: %{field: "has_notes", operator: "equals", value: true}
          }
        ]
      }

      # Notes visible but optional - should not be validated as required
      params = %{"has_notes" => true, "notes" => ""}
      changeset = Changeset.create_changeset(instance, params)

      assert changeset.valid?
    end
  end
end
