defmodule DynamicForm.Renderer do
  @moduledoc """
  A pure functional component that renders dynamic forms.

  This component renders the form HTML based on a DynamicForm.Instance configuration.
  Use this for advanced cases where you want custom state management.

  ## Example

      <DynamicForm.Renderer.render
        instance={@form_instance}
        form={@form}
        submit_text="Submit Form"
        phx_submit="submit"
        phx_change="validate"
        form_id="my-dynamic-form"
      />

  ## External Submit Button

  You can place a submit button outside the form element by:

  1. Setting `hide_submit` to `true`
  2. Using `DynamicForm.submit_button/1` anywhere on the page with the form's ID

  ### Example

      # Form without submit button
      <DynamicForm.Renderer.render
        instance={@form_instance}
        form={@form}
        form_id="my-form"
        hide_submit={true}
        phx_submit="submit"
      />

      # Submit button elsewhere on the page
      <div class="sticky bottom-0">
        <DynamicForm.submit_button form="my-form">
          Save Changes
        </DynamicForm.submit_button>
      </div>
  """

  use Phoenix.Component

  alias DynamicForm.CoreComponents
  alias DynamicForm.Instance

  attr(:instance, :any,
    required: true,
    doc:
      "The form instance configuration. Can be an Instance struct, JSON string, or map that will be decoded into an Instance."
  )

  attr(:form, Phoenix.HTML.Form, required: true, doc: "The Phoenix form struct")
  attr(:submit_text, :string, default: nil, doc: "Text for the submit button")
  attr(:phx_submit, :string, default: "submit", doc: "Phoenix event name for form submission")

  attr(:phx_change, :string,
    default: "validate",
    doc: "Phoenix event name for form validation"
  )

  attr(:target, :any, default: nil, doc: "Phoenix LiveView target for events")
  attr(:form_id, :string, default: "dynamic-form", doc: "HTML ID for the form element")
  attr(:disabled, :boolean, default: false, doc: "Whether the form is disabled")

  attr(:hide_submit, :boolean,
    default: false,
    doc: "Whether to hide the submit button (useful when using an external submit button)"
  )

  attr(:gettext, :atom,
    default: DynamicForm.Gettext,
    doc: "Gettext backend module for translations"
  )

  attr(:uploads, :map,
    default: %{},
    doc: "Upload configurations for direct_upload fields"
  )

  attr(:parent_id, :string,
    default: nil,
    doc: "Parent component ID for LiveComponent communication"
  )

  def render(assigns) do
    # Decode instance if needed
    instance = decode_instance(assigns.instance)
    submit_text = assigns.submit_text || "Submit"
    uploads = Map.get(assigns, :uploads, %{})
    parent_id = Map.get(assigns, :parent_id)

    assigns =
      assigns
      |> assign(:instance, instance)
      |> assign(:submit_text, submit_text)
      |> assign(:uploads, uploads)
      |> assign(:parent_id, parent_id)

    ~H"""
    <.form
      :let={f}
      for={@form}
      id={@form_id}
      phx-submit={@phx_submit}
      phx-change={@phx_change}
      phx-target={@target}
    >
      <%= for item <- visible_items(@instance.items, @form) do %>
        <%= render_item(item, f, disabled: @disabled, gettext: @gettext, uploads: @uploads, parent_id: @parent_id) %>
      <% end %>

      <div :if={!@hide_submit} class="mt-6 flex items-center justify-end gap-x-6">
        <button
          type="submit"
          disabled={@disabled}
          class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <%= if @disabled do %>
            Saving...
          <% else %>
            <%= @submit_text %>
          <% end %>
        </button>
      </div>
    </.form>
    """
  end

  # Filter items (fields and elements) based on visibility conditions
  defp visible_items(items, form) do
    Enum.filter(items, fn item ->
      should_display_item?(item, form)
    end)
  end

  # Item with no visibility condition is always visible
  defp should_display_item?(%Instance.Field{visible_when: nil}, _form), do: true
  defp should_display_item?(%Instance.Element{visible_when: nil}, _form), do: true

  # Item with visibility condition - check if condition is met
  defp should_display_item?(%Instance.Field{visible_when: condition}, form) do
    evaluate_condition(condition, form)
  end

  defp should_display_item?(%Instance.Element{visible_when: condition}, form) do
    evaluate_condition(condition, form)
  end

  # Evaluate "equals" operator with atom keys
  defp evaluate_condition(%{field: field_name, operator: "equals", value: expected}, form) do
    field_atom = String.to_existing_atom(field_name)
    current_value = Phoenix.HTML.Form.input_value(form, field_atom)
    current_value == expected
  rescue
    ArgumentError -> false
  end

  # Evaluate "equals" operator with string keys (from JSON decoding)
  defp evaluate_condition(
         %{"field" => field_name, "operator" => "equals", "value" => expected},
         form
       ) do
    field_atom = String.to_existing_atom(field_name)
    current_value = Phoenix.HTML.Form.input_value(form, field_atom)
    current_value == expected
  rescue
    ArgumentError -> false
  end

  # Evaluate "valid" operator with atom keys
  defp evaluate_condition(%{field: field_name, operator: "valid"}, form) do
    field_atom = String.to_existing_atom(field_name)
    current_value = Phoenix.HTML.Form.input_value(form, field_atom)

    # Check if field has a value (not nil, not empty string)
    has_value = current_value != nil and current_value != ""

    # Check if field has no errors in the changeset
    has_no_errors =
      case Keyword.get(form.errors || [], field_atom) do
        nil -> true
        _ -> false
      end

    has_value and has_no_errors
  rescue
    ArgumentError -> false
  end

  # Evaluate "valid" operator with string keys (from JSON decoding)
  defp evaluate_condition(%{"field" => field_name, "operator" => "valid"}, form) do
    field_atom = String.to_existing_atom(field_name)
    current_value = Phoenix.HTML.Form.input_value(form, field_atom)

    # Check if field has a value (not nil, not empty string)
    has_value = current_value != nil and current_value != ""

    # Check if field has no errors in the changeset
    has_no_errors =
      case Keyword.get(form.errors || [], field_atom) do
        nil -> true
        _ -> false
      end

    has_value and has_no_errors
  rescue
    ArgumentError -> false
  end

  # Dispatch to appropriate renderer based on item type
  defp render_item(%Instance.Field{} = field, form, opts) do
    render_field(field, form, opts)
  end

  defp render_item(%Instance.Element{} = element, form, opts) do
    render_element(element, form, opts)
  end

  # Render element types
  defp render_element(%Instance.Element{type: "heading"} = element, _form, _opts) do
    level = get_in(element.metadata || %{}, ["level"]) || "h2"
    content = element.content || ""

    assigns = %{level: level, content: content, element: element}

    ~H"""
    <div class="mb-6">
      <%= case @level do %>
        <% "h1" -> %>
          <h1 class="text-3xl font-bold text-gray-900"><%= @content %></h1>
        <% "h2" -> %>
          <h2 class="text-2xl font-semibold text-gray-900"><%= @content %></h2>
        <% "h3" -> %>
          <h3 class="text-xl font-semibold text-gray-900"><%= @content %></h3>
        <% "h4" -> %>
          <h4 class="text-lg font-semibold text-gray-900"><%= @content %></h4>
        <% "h5" -> %>
          <h5 class="text-base font-semibold text-gray-900"><%= @content %></h5>
        <% "h6" -> %>
          <h6 class="text-sm font-semibold text-gray-900"><%= @content %></h6>
        <% _ -> %>
          <h2 class="text-2xl font-semibold text-gray-900"><%= @content %></h2>
      <% end %>
    </div>
    """
  end

  defp render_element(%Instance.Element{type: "paragraph"} = element, _form, _opts) do
    content = element.content || ""
    custom_class = get_in(element.metadata || %{}, ["class"]) || "text-gray-700"

    assigns = %{content: content, custom_class: custom_class}

    ~H"""
    <div class="mb-4">
      <p class={@custom_class}><%= @content %></p>
    </div>
    """
  end

  defp render_element(%Instance.Element{type: "divider"}, _form, _opts) do
    assigns = %{}

    ~H"""
    <div class="my-6">
      <hr class="border-gray-300" />
    </div>
    """
  end

  defp render_element(%Instance.Element{type: "group"} = element, form, opts) do
    layout = get_in(element.metadata || %{}, ["layout"]) || "horizontal"
    content = element.content
    items = element.items || []

    assigns = %{
      element: element,
      content: content,
      layout: layout,
      items: items,
      form: form,
      opts: opts
    }

    ~H"""
    <CoreComponents.group title={@content} layout={@layout}>
      <%= for item <- @items do %>
        <%= case item do %>
          <% %Instance.Field{} = field -> %>
            <%= render_field(field, @form, @opts) %>
          <% %Instance.Element{} = nested_element -> %>
            <%= render_element(nested_element, @form, @opts) %>
        <% end %>
      <% end %>
    </CoreComponents.group>
    """
  end

  defp render_element(%Instance.Element{type: "section"} = element, form, opts) do
    content = element.content
    items = element.items || []
    custom_class = get_in(element.metadata || %{}, ["class"])

    # Filter visible items within the section
    visible_section_items = visible_items(items, form)

    assigns = %{
      element: element,
      content: content,
      custom_class: custom_class,
      items: visible_section_items,
      form: form,
      opts: opts
    }

    ~H"""
    <CoreComponents.section title={@content} class={@custom_class}>
      <%= for item <- @items do %>
        <%= case item do %>
          <% %Instance.Field{} = field -> %>
            <%= render_field(field, @form, @opts) %>
          <% %Instance.Element{} = nested_element -> %>
            <%= render_element(nested_element, @form, @opts) %>
        <% end %>
      <% end %>
    </CoreComponents.section>
    """
  end

  # Fallback for unknown element types
  defp render_element(element, _form, _opts) do
    assigns = %{element: element}

    ~H"""
    <div class="mb-4 rounded-md bg-yellow-50 p-4">
      <div class="flex">
        <div class="ml-3">
          <h3 class="text-sm font-medium text-yellow-800">Unknown element type</h3>
          <div class="mt-2 text-sm text-yellow-700">
            <p>Element "<%= @element.id %>" has unsupported type: <%= @element.type %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Render a string/text input field
  defp render_field(%Instance.Field{type: "string"} = field, form, opts) do
    form_disabled = Keyword.get(opts, :disabled, false)
    disabled = form_disabled || field.disabled || false
    field_atom = String.to_atom(field.name)

    # Build label with required indicator
    label =
      if field.required do
        Phoenix.HTML.raw(
          "#{field.label || String.capitalize(field.name)} <span class=\"text-red-500\">*</span>"
        )
      else
        field.label || String.capitalize(field.name)
      end

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled,
      label: label
    }

    ~H"""
    <div class="mb-4">
      <CoreComponents.input
        field={@form[@field_atom]}
        type="text"
        label={@label}
        placeholder={@field.placeholder}
        disabled={@disabled}
      />
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
    </div>
    """
  end

  # Render an email input field
  defp render_field(%Instance.Field{type: "email"} = field, form, opts) do
    form_disabled = Keyword.get(opts, :disabled, false)
    disabled = form_disabled || field.disabled || false
    field_atom = String.to_atom(field.name)

    # Build label with required indicator
    label =
      if field.required do
        Phoenix.HTML.raw(
          "#{field.label || String.capitalize(field.name)} <span class=\"text-red-500\">*</span>"
        )
      else
        field.label || String.capitalize(field.name)
      end

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled,
      label: label
    }

    ~H"""
    <div class="mb-4">
      <CoreComponents.input
        field={@form[@field_atom]}
        type="email"
        label={@label}
        placeholder={@field.placeholder}
        disabled={@disabled}
      />
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
    </div>
    """
  end

  # Render a textarea field
  defp render_field(%Instance.Field{type: "textarea"} = field, form, opts) do
    form_disabled = Keyword.get(opts, :disabled, false)
    disabled = form_disabled || field.disabled || false
    field_atom = String.to_atom(field.name)

    # Build label with required indicator
    label =
      if field.required do
        Phoenix.HTML.raw(
          "#{field.label || String.capitalize(field.name)} <span class=\"text-red-500\">*</span>"
        )
      else
        field.label || String.capitalize(field.name)
      end

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled,
      label: label
    }

    ~H"""
    <div class="mb-4">
      <CoreComponents.input
        field={@form[@field_atom]}
        type="textarea"
        label={@label}
        placeholder={@field.placeholder}
        disabled={@disabled}
        rows="4"
      />
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
    </div>
    """
  end

  # Render a decimal/number input field
  defp render_field(%Instance.Field{type: "decimal"} = field, form, opts) do
    form_disabled = Keyword.get(opts, :disabled, false)
    disabled = form_disabled || field.disabled || false
    field_atom = String.to_atom(field.name)

    # Build label with required indicator
    label =
      if field.required do
        Phoenix.HTML.raw(
          "#{field.label || String.capitalize(field.name)} <span class=\"text-red-500\">*</span>"
        )
      else
        field.label || String.capitalize(field.name)
      end

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled,
      label: label
    }

    ~H"""
    <div class="mb-4">
      <CoreComponents.input
        field={@form[@field_atom]}
        type="number"
        label={@label}
        placeholder={@field.placeholder}
        disabled={@disabled}
        step="0.01"
      />
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
    </div>
    """
  end

  # Render a boolean/checkbox field
  defp render_field(%Instance.Field{type: "boolean"} = field, form, opts) do
    form_disabled = Keyword.get(opts, :disabled, false)
    disabled = form_disabled || field.disabled || false
    field_atom = String.to_atom(field.name)

    # For checkboxes, the label is displayed inline, so include help_text if present
    label =
      if field.help_text do
        Phoenix.HTML.raw(
          "#{field.label || String.capitalize(field.name)}<br><span class=\"text-gray-500\">#{field.help_text}</span>"
        )
      else
        field.label || String.capitalize(field.name)
      end

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled,
      label: label
    }

    ~H"""
    <div class="mb-4">
      <CoreComponents.input
        field={@form[@field_atom]}
        type="checkbox"
        label={@label}
        disabled={@disabled}
      />
    </div>
    """
  end

  # Render a select/dropdown field
  defp render_field(%Instance.Field{type: "select"} = field, form, opts) do
    form_disabled = Keyword.get(opts, :disabled, false)
    disabled = form_disabled || field.disabled || false
    field_atom = String.to_atom(field.name)
    options = field.options || []

    # Build label with required indicator
    label =
      if field.required do
        Phoenix.HTML.raw(
          "#{field.label || String.capitalize(field.name)} <span class=\"text-red-500\">*</span>"
        )
      else
        field.label || String.capitalize(field.name)
      end

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled,
      options: options,
      label: label
    }

    ~H"""
    <div class="mb-4">
      <CoreComponents.input
        field={@form[@field_atom]}
        type="select"
        label={@label}
        options={@options}
        prompt="Select an option..."
        disabled={@disabled}
      />
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
    </div>
    """
  end

  # Render a radio-group field
  defp render_field(%Instance.Field{type: "radio-group"} = field, form, opts) do
    form_disabled = Keyword.get(opts, :disabled, false)
    disabled = form_disabled || field.disabled || false
    field_atom = String.to_atom(field.name)
    options = field.options || []

    # Get style from metadata and convert to atom if needed
    style =
      case get_in(field.metadata || %{}, ["style"]) do
        "horizontal" -> :horizontal
        "vertical" -> :vertical
        :horizontal -> :horizontal
        :vertical -> :vertical
        _ -> :vertical
      end

    # Build label with required indicator
    label =
      if field.required do
        Phoenix.HTML.raw(
          "#{field.label || String.capitalize(field.name)} <span class=\"text-red-500\">*</span>"
        )
      else
        field.label || String.capitalize(field.name)
      end

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled,
      options: options,
      label: label,
      style: style
    }

    ~H"""
    <div class="mb-4">
      <CoreComponents.input_radio_group
        field={@form[@field_atom]}
        label={@label}
        options={@options}
        style={@style}
        disabled={@disabled}
      />
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
    </div>
    """
  end

  # Render a standalone radio field (for custom layouts)
  defp render_field(%Instance.Field{type: "radio"} = field, form, opts) do
    form_disabled = Keyword.get(opts, :disabled, false)
    disabled = form_disabled || field.disabled || false
    field_atom = String.to_atom(field.name)
    value = field.default_value || get_in(field.metadata || %{}, ["value"]) || ""
    current_value = Phoenix.HTML.Form.input_value(form, field_atom)
    checked = to_string(current_value) == to_string(value)

    label = field.label || String.capitalize(field.name)

    # Get id for the radio input
    id = "#{field.id}-#{value}"
    name = field.name

    assigns = %{
      field: field,
      disabled: disabled,
      label: label,
      value: value,
      checked: checked,
      id: id,
      name: name
    }

    ~H"""
    <div class="mb-4">
      <label class="flex items-center text-sm leading-6 text-zinc-600">
        <CoreComponents.input_radio
          id={@id}
          name={@name}
          value={@value}
          checked={@checked}
          disabled={@disabled}
        />
        {@label}
      </label>
      <%= if @field.help_text do %>
        <p class="mt-2 ml-7 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
    </div>
    """
  end

  # Render a direct_upload field (file upload to cloud storage)
  defp render_field(%Instance.Field{type: "direct_upload"} = field, form, opts) do
    form_disabled = Keyword.get(opts, :disabled, false)
    disabled = form_disabled || field.disabled || false
    uploads = Keyword.get(opts, :uploads, %{})
    parent_id = Keyword.get(opts, :parent_id)

    assigns = %{
      field: field,
      form: form,
      disabled: disabled,
      uploads: uploads,
      parent_id: parent_id
    }

    ~H"""
    <.live_component
      module={DynamicForm.DirectUpload}
      id={"#{@field.id}-upload-component"}
      field={@field}
      form={@form}
      disabled={@disabled}
      uploads={@uploads}
      parent_id={@parent_id}
    />
    """
  end

  # Fallback for unknown field types
  defp render_field(field, _form, _opts) do
    assigns = %{field: field}

    ~H"""
    <div class="mb-4 rounded-md bg-red-50 p-4">
      <div class="flex">
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800">Unknown field type</h3>
          <div class="mt-2 text-sm text-red-700">
            <p>Field "<%= @field.name %>" has unsupported type: <%= @field.type %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper to decode instance from various formats
  defp decode_instance(%Instance{} = instance), do: instance

  defp decode_instance(data) when is_binary(data) or is_map(data) do
    Instance.decode!(data)
  end
end
