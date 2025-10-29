defmodule DynamicForm.Instance do
  @moduledoc """
  Configuration struct that defines the complete form structure, including backend configuration.

  An Instance represents a complete form definition with all its items (fields and elements),
  validations, and backend submission configuration.

  ## Example

      iex> instance = %DynamicForm.Instance{
      ...>   id: "contact-form",
      ...>   name: "Contact Form",
      ...>   description: "Get in touch with us",
      ...>   items: [
      ...>     %DynamicForm.Instance.Element{
      ...>       id: "section-heading",
      ...>       type: "heading",
      ...>       content: "Contact Information"
      ...>     },
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
      ...>     function: :submit,
      ...>     config: [recipient: "admin@example.com"]
      ...>   }
      ...> }

  ## JSON Encoding/Decoding

  Instances can be encoded to JSON and decoded back:

      # Encode to JSON
      json = Jason.encode!(instance)

      # Decode from JSON
      instance = DynamicForm.Instance.decode!(json)

      # Decode from map
      instance = DynamicForm.Instance.decode!(map)
  """

  @enforce_keys [:id, :items]
  defstruct [
    :id,
    :name,
    :description,
    :items,
    :backend,
    :metadata,
    inserted_at: nil,
    updated_at: nil
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t() | nil,
          description: String.t() | nil,
          items: [Field.t() | Element.t()],
          backend: Backend.t(),
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc """
  Decodes a JSON string or map into a DynamicForm.Instance struct.

  ## Examples

      iex> json = ~s({"id": "my-form", "name": "My Form", "items": []})
      iex> DynamicForm.Instance.decode!(json)
      %DynamicForm.Instance{id: "my-form", name: "My Form", items: []}

      iex> map = %{"id" => "my-form", "name" => "My Form", "items" => []}
      iex> DynamicForm.Instance.decode!(map)
      %DynamicForm.Instance{id: "my-form", name: "My Form", items: []}
  """
  def decode!(data) when is_binary(data) do
    data
    |> Jason.decode!()
    |> decode!()
  end

  def decode!(data) when is_map(data) do
    DynamicForm.Instance.Decoder.decode_instance(data)
  end

  defmodule Field do
    @moduledoc """
    Represents a single form field with its configuration and validation rules.

    ## Disabled Fields

    Fields can be marked as `disabled: true` to prevent user editing while still
    displaying the field value. This is commonly used in edit forms where certain
    fields (like IDs, creation timestamps, or verified emails) should be visible
    but immutable.

    **Important**: Disabled HTML fields are not submitted by browsers. The
    `DynamicForm.RendererLive` component automatically preserves disabled field
    values by merging the initial params with form submissions.

    ### Example

        %Field{
          id: "user_id",
          name: "user_id",
          type: "string",
          label: "User ID",
          disabled: true
        }

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
      :required,
      :disabled,
      :visible_when,
      :metadata,
      __type__: "Field"
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
            required: boolean() | nil,
            disabled: boolean() | nil,
            visible_when: condition() | nil,
            metadata: map() | nil,
            __type__: String.t()
          }
  end

  defimpl Jason.Encoder, for: Field do
    def encode(field, opts) do
      Jason.Encode.map(
        %{
          id: field.id,
          name: field.name,
          type: field.type,
          label: field.label,
          placeholder: field.placeholder,
          help_text: field.help_text,
          default_value: field.default_value,
          options: encode_options(field.options),
          validations: field.validations,
          required: field.required,
          disabled: field.disabled,
          visible_when: field.visible_when,
          metadata: field.metadata,
          __type__: field.__type__
        },
        opts
      )
    end

    # Convert tuple options {label, value} to arrays [label, value] for JSON
    defp encode_options(nil), do: nil
    defp encode_options([]), do: []

    defp encode_options(options) when is_list(options) do
      Enum.map(options, fn
        {label, value} -> [label, value]
        other -> other
      end)
    end
  end

  defmodule Element do
    @moduledoc """
    Represents a non-input element in a form, such as headings, paragraphs, dividers, or groups.

    Elements are used to add structure and information to forms without collecting user input.
    They support conditional visibility just like fields.

    ## Supported Types

    - `"heading"` - Section heading (h1-h6)
    - `"paragraph"` - Text paragraph for instructions or information
    - `"divider"` - Horizontal line to separate sections
    - `"group"` - Container for grouping fields together with layout options

    ## Examples

        # Heading element
        %Element{
          id: "section-1",
          type: "heading",
          content: "Personal Information",
          position: 1,
          metadata: %{"level" => "h2"}
        }

        # Paragraph element
        %Element{
          id: "privacy-notice",
          type: "paragraph",
          content: "We take your privacy seriously. Your data will never be shared.",
          position: 2,
          metadata: %{"class" => "text-gray-600"}
        }

        # Divider element
        %Element{
          id: "divider-1",
          type: "divider",
          position: 3
        }

        # Group element with nested fields
        %Element{
          id: "address-group",
          type: "group",
          content: "Shipping Address",
          position: 4,
          metadata: %{"layout" => "grid-2"},
          items: [
            %Field{
              id: "street",
              name: "street",
              type: "string",
              label: "Street"
            },
            %Field{
              id: "city",
              name: "city",
              type: "string",
              label: "City"
            }
          ]
        }

        # Conditional element (only show when terms accepted)
        %Element{
          id: "thank-you-message",
          type: "paragraph",
          content: "Thank you for accepting our terms!",
          visible_when: %{
            field: "accept_terms",
            operator: "equals",
            value: true
          }
        }
    """

    @derive Jason.Encoder
    @enforce_keys [:id, :type]
    defstruct [
      :id,
      :type,
      :content,
      :items,
      :visible_when,
      :metadata,
      __type__: "Element"
    ]

    @type condition :: %{
            field: String.t(),
            operator: String.t(),
            value: any()
          }

    @type t :: %__MODULE__{
            id: String.t(),
            type: String.t(),
            content: String.t() | nil,
            items: [Field.t() | t()] | nil,
            visible_when: condition() | nil,
            metadata: map() | nil,
            __type__: String.t()
          }
  end

  defmodule Backend do
    @moduledoc """
    Configuration for the form submission backend.

    The backend module should implement the `DynamicForm.Backend` behaviour.

    ## Example

        %Backend{
          module: MyApp.EmailBackend,
          function: :submit,
          config: [recipient: "admin@example.com"],
          name: "Email Backend",
          description: "Sends form submissions via email"
        }
    """

    @enforce_keys [:module, :function, :config]
    defstruct [
      :module,
      :function,
      :config,
      :name,
      :description
    ]

    @type t :: %__MODULE__{
            module: module(),
            function: atom(),
            config: Keyword.t(),
            name: String.t() | nil,
            description: String.t() | nil
          }
  end

  defimpl Jason.Encoder, for: Backend do
    def encode(backend, opts) do
      Jason.Encode.map(
        %{
          module: to_string(backend.module),
          function: backend.function,
          config: encode_config(backend.config),
          name: backend.name,
          description: backend.description
        },
        opts
      )
    end

    # Convert keyword list to a list of maps for JSON serialization
    defp encode_config(config) when is_list(config) do
      Enum.map(config, fn {key, value} ->
        %{"key" => to_string(key), "value" => value}
      end)
    end

    defp encode_config(config), do: config
  end

  defmodule Validation do
    @moduledoc """
    Represents a validation rule for a form field.
    """

    @derive Jason.Encoder
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

  # Custom encoder for Instance that handles DateTime fields
  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(instance, opts) do
      Jason.Encode.map(
        %{
          id: instance.id,
          name: instance.name,
          description: instance.description,
          items: instance.items,
          backend: instance.backend,
          metadata: instance.metadata,
          inserted_at: encode_datetime(instance.inserted_at),
          updated_at: encode_datetime(instance.updated_at)
        },
        opts
      )
    end

    defp encode_datetime(nil), do: nil
    defp encode_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  end
end
