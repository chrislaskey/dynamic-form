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
  """

  use Phoenix.Component

  alias DynamicForm.Instance

  attr(:instance, Instance, required: true, doc: "The form instance configuration")
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

  def render(assigns) do
    submit_text = assigns.submit_text || "Submit"
    assigns = assign(assigns, :submit_text, submit_text)

    ~H"""
    <.form
      :let={f}
      for={@form}
      id={@form_id}
      phx-submit={@phx_submit}
      phx-change={@phx_change}
      phx-target={@target}
    >
      <%= for field <- @instance.fields do %>
        <%= render_field(field, f, disabled: @disabled) %>
      <% end %>

      <div class="mt-6 flex items-center justify-end gap-x-6">
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

  # Render a string/text input field
  defp render_field(%Instance.Field{type: "string"} = field, form, opts) do
    disabled = Keyword.get(opts, :disabled, false)
    field_atom = String.to_atom(field.name)

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled
    }

    ~H"""
    <div class="mb-4">
      <label for={@field.name} class="block text-sm font-medium leading-6 text-gray-900">
        <%= @field.label || String.capitalize(@field.name) %>
        <%= if @field.required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <div class="mt-2">
        <input
          type="text"
          name={Phoenix.HTML.Form.input_name(@form, @field_atom)}
          id={Phoenix.HTML.Form.input_id(@form, @field_atom)}
          value={Phoenix.HTML.Form.input_value(@form, @field_atom)}
          placeholder={@field.placeholder}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:opacity-50"
        />
      </div>
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
      <%= if error = Keyword.get(@form.errors || [], @field_atom) do %>
        <p class="mt-2 text-sm text-red-600"><%= translate_error(error) %></p>
      <% end %>
    </div>
    """
  end

  # Render an email input field
  defp render_field(%Instance.Field{type: "email"} = field, form, opts) do
    disabled = Keyword.get(opts, :disabled, false)
    field_atom = String.to_atom(field.name)

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled
    }

    ~H"""
    <div class="mb-4">
      <label for={@field.name} class="block text-sm font-medium leading-6 text-gray-900">
        <%= @field.label || String.capitalize(@field.name) %>
        <%= if @field.required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <div class="mt-2">
        <input
          type="email"
          name={Phoenix.HTML.Form.input_name(@form, @field_atom)}
          id={Phoenix.HTML.Form.input_id(@form, @field_atom)}
          value={Phoenix.HTML.Form.input_value(@form, @field_atom)}
          placeholder={@field.placeholder}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:opacity-50"
        />
      </div>
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
      <%= if error = Keyword.get(@form.errors || [], @field_atom) do %>
        <p class="mt-2 text-sm text-red-600"><%= translate_error(error) %></p>
      <% end %>
    </div>
    """
  end

  # Render a textarea field
  defp render_field(%Instance.Field{type: "textarea"} = field, form, opts) do
    disabled = Keyword.get(opts, :disabled, false)
    field_atom = String.to_atom(field.name)

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled
    }

    ~H"""
    <div class="mb-4">
      <label for={@field.name} class="block text-sm font-medium leading-6 text-gray-900">
        <%= @field.label || String.capitalize(@field.name) %>
        <%= if @field.required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <div class="mt-2">
        <textarea
          name={Phoenix.HTML.Form.input_name(@form, @field_atom)}
          id={Phoenix.HTML.Form.input_id(@form, @field_atom)}
          placeholder={@field.placeholder}
          disabled={@disabled}
          rows="4"
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:opacity-50"
        ><%= Phoenix.HTML.Form.input_value(@form, @field_atom) %></textarea>
      </div>
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
      <%= if error = Keyword.get(@form.errors || [], @field_atom) do %>
        <p class="mt-2 text-sm text-red-600"><%= translate_error(error) %></p>
      <% end %>
    </div>
    """
  end

  # Render a decimal/number input field
  defp render_field(%Instance.Field{type: "decimal"} = field, form, opts) do
    disabled = Keyword.get(opts, :disabled, false)
    field_atom = String.to_atom(field.name)

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled
    }

    ~H"""
    <div class="mb-4">
      <label for={@field.name} class="block text-sm font-medium leading-6 text-gray-900">
        <%= @field.label || String.capitalize(@field.name) %>
        <%= if @field.required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <div class="mt-2">
        <input
          type="number"
          step="0.01"
          name={Phoenix.HTML.Form.input_name(@form, @field_atom)}
          id={Phoenix.HTML.Form.input_id(@form, @field_atom)}
          value={Phoenix.HTML.Form.input_value(@form, @field_atom)}
          placeholder={@field.placeholder}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:opacity-50"
        />
      </div>
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
      <%= if error = Keyword.get(@form.errors || [], @field_atom) do %>
        <p class="mt-2 text-sm text-red-600"><%= translate_error(error) %></p>
      <% end %>
    </div>
    """
  end

  # Render a boolean/checkbox field
  defp render_field(%Instance.Field{type: "boolean"} = field, form, opts) do
    disabled = Keyword.get(opts, :disabled, false)
    field_atom = String.to_atom(field.name)

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled
    }

    ~H"""
    <div class="mb-4">
      <div class="relative flex gap-x-3">
        <div class="flex h-6 items-center">
          <input
            type="checkbox"
            name={Phoenix.HTML.Form.input_name(@form, @field_atom)}
            id={Phoenix.HTML.Form.input_id(@form, @field_atom)}
            value="true"
            checked={Phoenix.HTML.Form.input_value(@form, @field_atom) == true}
            disabled={@disabled}
            class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600 disabled:opacity-50"
          />
        </div>
        <div class="text-sm leading-6">
          <label for={@field.name} class="font-medium text-gray-900">
            <%= @field.label || String.capitalize(@field.name) %>
          </label>
          <%= if @field.help_text do %>
            <p class="text-gray-500"><%= @field.help_text %></p>
          <% end %>
        </div>
      </div>
      <%= if error = Keyword.get(@form.errors || [], @field_atom) do %>
        <p class="mt-2 text-sm text-red-600"><%= translate_error(error) %></p>
      <% end %>
    </div>
    """
  end

  # Render a select/dropdown field
  defp render_field(%Instance.Field{type: "select"} = field, form, opts) do
    disabled = Keyword.get(opts, :disabled, false)
    field_atom = String.to_atom(field.name)
    options = field.options || []

    assigns = %{
      field: field,
      form: form,
      field_atom: field_atom,
      disabled: disabled,
      options: options
    }

    ~H"""
    <div class="mb-4">
      <label for={@field.name} class="block text-sm font-medium leading-6 text-gray-900">
        <%= @field.label || String.capitalize(@field.name) %>
        <%= if @field.required do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>
      <div class="mt-2">
        <select
          name={Phoenix.HTML.Form.input_name(@form, @field_atom)}
          id={Phoenix.HTML.Form.input_id(@form, @field_atom)}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:opacity-50"
        >
          <option value="">Select an option...</option>
          <%= for {label, value} <- @options do %>
            <option
              value={value}
              selected={Phoenix.HTML.Form.input_value(@form, @field_atom) == value}
            >
              <%= label %>
            </option>
          <% end %>
        </select>
      </div>
      <%= if @field.help_text do %>
        <p class="mt-2 text-sm text-gray-500"><%= @field.help_text %></p>
      <% end %>
      <%= if error = Keyword.get(@form.errors || [], @field_atom) do %>
        <p class="mt-2 text-sm text-red-600"><%= translate_error(error) %></p>
      <% end %>
    </div>
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

  # Helper function to translate errors
  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp translate_error(msg) when is_binary(msg), do: msg
end
