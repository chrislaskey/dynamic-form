defmodule Example.FormInstances do
  @moduledoc """
  Shared form instance configurations for testing DynamicForm renderers.

  This module provides reusable form instances that can be used across
  multiple test pages and examples.
  """

  alias DynamicForm.Instance

  @doc """
  Returns a contact form instance with various field types.

  This form includes:
  - String field (name)
  - Email field with format validation
  - Select field (subject)
  - Textarea field (message) with length validation
  - Decimal field (priority) with numeric range validation
  - Boolean field (subscribe)
  """
  def contact_form do
    %Instance{
      id: "contact-form",
      name: "Contact Form",
      description: "Please fill out this form to get in touch with us.",
      fields: [
        %Instance.Field{
          id: "name",
          name: "name",
          type: "string",
          label: "Full Name",
          placeholder: "John Doe",
          help_text: "Enter your full name as it appears on official documents",
          required: true,
          position: 1,
          validations: [
            %Instance.Validation{type: "min_length", value: 2}
          ]
        },
        %Instance.Field{
          id: "email",
          name: "email",
          type: "email",
          label: "Email Address",
          placeholder: "john@example.com",
          help_text: "We'll never share your email with anyone else",
          required: true,
          position: 2,
          validations: [
            %Instance.Validation{type: "email_format"}
          ]
        },
        %Instance.Field{
          id: "subject",
          name: "subject",
          type: "select",
          label: "Subject",
          help_text: "Choose the topic that best matches your inquiry",
          required: true,
          position: 3,
          options: [
            {"General Inquiry", "general"},
            {"Technical Support", "support"},
            {"Sales", "sales"},
            {"Feedback", "feedback"}
          ]
        },
        %Instance.Field{
          id: "message",
          name: "message",
          type: "textarea",
          label: "Message",
          placeholder: "Tell us how we can help you...",
          help_text: "Please provide as much detail as possible",
          required: true,
          position: 4,
          validations: [
            %Instance.Validation{type: "min_length", value: 10},
            %Instance.Validation{type: "max_length", value: 1000}
          ]
        },
        %Instance.Field{
          id: "priority",
          name: "priority",
          type: "decimal",
          label: "Priority (1-10)",
          placeholder: "5",
          help_text: "Rate the urgency of your request from 1 (low) to 10 (high)",
          required: false,
          position: 5,
          validations: [
            %Instance.Validation{type: "numeric_range", min: 1, max: 10}
          ]
        },
        %Instance.Field{
          id: "subscribe",
          name: "subscribe",
          type: "boolean",
          label: "Subscribe to newsletter",
          help_text: "Receive updates about new features and announcements",
          required: false,
          position: 6
        },
        %Instance.Field{
          id: "newsletter_frequency",
          name: "newsletter_frequency",
          type: "select",
          label: "Newsletter Frequency",
          help_text: "How often would you like to receive our newsletter?",
          required: false,
          position: 7,
          visible_when: %{
            field: "email",
            operator: "valid"
          },
          options: [
            {"Daily", "daily"},
            {"Weekly", "weekly"},
            {"Monthly", "monthly"}
          ]
        }
      ],
      backend: %Instance.Backend{
        module: Example.TestBackend,
        config: [],
        name: "Test Backend",
        description: "Logs form submissions for testing"
      },
      metadata: %{
        created_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Returns a payment form that demonstrates conditional field visibility.

  This form shows how fields can be conditionally displayed based on other field values:
  - Credit card fields only appear when payment method is "credit_card"
  - Bank account fields only appear when payment method is "bank_transfer"
  """
  def payment_form do
    %Instance{
      id: "payment-form",
      name: "Payment Form",
      description: "Complete your payment information below.",
      fields: [
        %Instance.Field{
          id: "payment_method",
          name: "payment_method",
          type: "select",
          label: "Payment Method",
          help_text: "Choose how you would like to pay",
          required: true,
          position: 1,
          options: [
            {"Credit Card", "credit_card"},
            {"Bank Transfer", "bank_transfer"},
            {"PayPal", "paypal"}
          ]
        },
        # Credit card fields - only visible when payment_method is "credit_card"
        %Instance.Field{
          id: "card_number",
          name: "card_number",
          type: "string",
          label: "Card Number",
          placeholder: "1234 5678 9012 3456",
          help_text: "Enter your 16-digit card number",
          required: false,
          position: 2,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "credit_card"
          },
          validations: [
            %Instance.Validation{type: "min_length", value: 13}
          ]
        },
        %Instance.Field{
          id: "card_expiry",
          name: "card_expiry",
          type: "string",
          label: "Expiry Date",
          placeholder: "MM/YY",
          help_text: "Card expiration date",
          required: false,
          position: 3,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "credit_card"
          }
        },
        %Instance.Field{
          id: "card_cvv",
          name: "card_cvv",
          type: "string",
          label: "CVV",
          placeholder: "123",
          help_text: "3-digit security code on the back of your card",
          required: false,
          position: 4,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "credit_card"
          },
          validations: [
            %Instance.Validation{type: "min_length", value: 3},
            %Instance.Validation{type: "max_length", value: 4}
          ]
        },
        # Bank transfer fields - only visible when payment_method is "bank_transfer"
        %Instance.Field{
          id: "account_number",
          name: "account_number",
          type: "string",
          label: "Account Number",
          placeholder: "1234567890",
          help_text: "Your bank account number",
          required: false,
          position: 5,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "bank_transfer"
          }
        },
        %Instance.Field{
          id: "routing_number",
          name: "routing_number",
          type: "string",
          label: "Routing Number",
          placeholder: "021000021",
          help_text: "9-digit routing number for your bank",
          required: false,
          position: 6,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "bank_transfer"
          },
          validations: [
            %Instance.Validation{type: "min_length", value: 9},
            %Instance.Validation{type: "max_length", value: 9}
          ]
        },
        # PayPal email - only visible when payment_method is "paypal"
        %Instance.Field{
          id: "paypal_email",
          name: "paypal_email",
          type: "email",
          label: "PayPal Email",
          placeholder: "you@example.com",
          help_text: "Email address associated with your PayPal account",
          required: false,
          position: 7,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "paypal"
          },
          validations: [
            %Instance.Validation{type: "email_format"}
          ]
        },
        # Amount field - always visible
        %Instance.Field{
          id: "amount",
          name: "amount",
          type: "decimal",
          label: "Amount",
          placeholder: "100.00",
          help_text: "Enter the payment amount in USD",
          required: true,
          position: 8,
          validations: [
            %Instance.Validation{type: "numeric_range", min: 0.01, max: 10000}
          ]
        },
        # Save payment method checkbox - always visible
        %Instance.Field{
          id: "save_method",
          name: "save_method",
          type: "boolean",
          label: "Save this payment method for future use",
          help_text: "Securely store your payment details",
          required: false,
          position: 9
        }
      ],
      backend: %Instance.Backend{
        module: Example.TestBackend,
        config: [],
        name: "Test Backend",
        description: "Logs form submissions for testing"
      },
      metadata: %{
        created_at: DateTime.utc_now()
      }
    }
  end
end
