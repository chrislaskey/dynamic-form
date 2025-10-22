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
      :metadata
    ]

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
