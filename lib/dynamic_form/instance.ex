defmodule DynamicForm.Instance do
  @moduledoc """
  Configuration struct that defines the complete form structure, including backend configuration.

  An Instance represents a complete form definition with all its fields, validations, and backend
  submission configuration.

  ## Example

      iex> instance = %DynamicForm.Instance{
      ...>   id: "contact-form",
      ...>   name: "Contact Form",
      ...>   description: "Get in touch with us",
      ...>   fields: [
      ...>     %DynamicForm.Instance.Field{
      ...>       id: "email",
      ...>       name: "email",
      ...>       type: "email",
      ...>       label: "Email Address",
      ...>       required: true
      ...>     }
      ...>   ],
      ...>   backend: %DynamicForm.Instance.Backend{
      ...>     module: MyApp.EmailBackend,
      ...>     config: [recipient: "admin@example.com"]
      ...>   }
      ...> }
  """

  @enforce_keys [:id, :name, :fields, :backend]
  defstruct [
    :id,
    :name,
    :description,
    :fields,
    :backend,
    :metadata,
    inserted_at: nil,
    updated_at: nil
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t() | nil,
          fields: [Field.t()],
          backend: Backend.t(),
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defmodule Field do
    @moduledoc """
    Represents a single form field with its configuration and validation rules.

    ## Conditional Visibility

    Fields can be conditionally shown based on the value of another field using the
    `visible_when` option. When `visible_when` is `nil`, the field is always visible.

    ### Supported Operators

    - `"equals"` - Field value must equal the specified value
    - `"valid"` - Field must be valid (has a value and passes all validations)

    ### Examples

        # Show field when payment_method equals "credit_card"
        %Field{
          id: "credit_card_number",
          name: "credit_card_number",
          type: "string",
          label: "Credit Card Number",
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "credit_card"
          }
        }

        # Show field when email is valid (filled and passes email validation)
        %Field{
          id: "email_preferences",
          name: "email_preferences",
          type: "select",
          label: "Email Preferences",
          visible_when: %{
            field: "email",
            operator: "valid"
          }
        }
    """

    @enforce_keys [:id, :name, :type]
    defstruct [
      :id,
      :name,
      :type,
      :label,
      :placeholder,
      :help_text,
      :default_value,
      :options,
      :validations,
      :position,
      :required,
      :visible_when,
      :metadata
    ]

    @type condition :: %{
            field: String.t(),
            operator: String.t(),
            value: any()
          }

    @type t :: %__MODULE__{
            id: String.t(),
            name: String.t(),
            type: String.t(),
            label: String.t() | nil,
            placeholder: String.t() | nil,
            help_text: String.t() | nil,
            default_value: any(),
            options: list() | nil,
            validations: [Validation.t()] | nil,
            position: integer() | nil,
            required: boolean() | nil,
            visible_when: condition() | nil,
            metadata: map() | nil
          }
  end

  defmodule Backend do
    @moduledoc """
    Configuration for the form submission backend.

    The backend module should implement the `DynamicForm.Backend` behaviour.
    """

    @enforce_keys [:module, :config]
    defstruct [
      :module,
      :config,
      :name,
      :description
    ]

    @type t :: %__MODULE__{
            module: module(),
            config: Keyword.t(),
            name: String.t() | nil,
            description: String.t() | nil
          }
  end

  defmodule Validation do
    @moduledoc """
    Represents a validation rule for a form field.
    """

    @enforce_keys [:type]
    defstruct [
      :type,
      :value,
      :min,
      :max,
      :message
    ]

    @type t :: %__MODULE__{
            type: String.t(),
            value: any() | nil,
            min: number() | nil,
            max: number() | nil,
            message: String.t() | nil
          }
  end
end
