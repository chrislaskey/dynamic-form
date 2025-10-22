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
