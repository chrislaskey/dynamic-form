defmodule ExampleWeb.SectionFormLive do
  use ExampleWeb, :live_view

  alias DynamicForm.Changeset

  @impl true
  def mount(_params, _session, socket) do
    # Get section form instance
    form_instance = Example.FormInstances.section_form()

    # Create initial changeset
    changeset = Changeset.create_changeset(form_instance, %{})
    form = to_form(changeset, as: "form")

    {:ok,
     socket
     |> assign(:form_instance, form_instance)
     |> assign(:changeset, changeset)
     |> assign(:form, form)
     |> assign(:submitted_data, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Section Element Demo</h1>
        <p class="mt-2 text-gray-600">
          This form demonstrates the new Section element for organizing form content.
        </p>
      </div>

      <div class="rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5 p-6">
        <DynamicForm.Renderer.render
          instance={@form_instance}
          form={@form}
          submit_text="Save Profile"
          phx_submit="submit"
          phx_change="validate"
          form_id="section-form"
        />
      </div>

      <%= if @submitted_data do %>
        <div class="mt-8 rounded-lg bg-green-50 p-6">
          <h3 class="text-lg font-semibold text-green-900 mb-4">✓ Profile Saved Successfully!</h3>
          <div class="text-sm text-green-800">
            <p class="font-semibold mb-2">Submitted Data:</p>
            <pre class="bg-green-100 p-4 rounded overflow-x-auto"><%= inspect(@submitted_data, pretty: true) %></pre>
          </div>
        </div>
      <% end %>

      <div class="mt-8 rounded-lg bg-blue-50 p-6">
        <h3 class="text-lg font-semibold text-blue-900 mb-4">📦 Section Features</h3>
        <div class="text-sm text-blue-800 space-y-3">
          <div>
            <strong>What is a Section?</strong>
            <p class="mt-1">
              A Section is a visual container element that groups related form content together.
              It renders as a card-like block with a border, rounded corners, and padding.
            </p>
          </div>

          <div>
            <strong>Section Capabilities:</strong>
            <ul class="list-disc list-inside ml-4 mt-1">
              <li>Optional title displayed at the top</li>
              <li>Can contain fields, groups, and other elements</li>
              <li>Supports nested sections (section within a section)</li>
              <li>Custom CSS classes via metadata</li>
              <li>Conditional visibility (show/hide based on field values)</li>
            </ul>
          </div>

          <div>
            <strong>Sections in this Form:</strong>
            <ul class="list-disc list-inside ml-4 mt-1">
              <li><strong>Personal Information</strong> - Contains name group and email field</li>
              <li><strong>Address</strong> - Contains street and city/state/zip group</li>
              <li>
                <strong>Preferences</strong>
                - Contains newsletter checkbox with conditional frequency field
              </li>
              <li>
                <strong>Additional Information</strong> - Contains bio field and a nested
                "Social Media Links" section
              </li>
            </ul>
          </div>

          <div>
            <strong>Section vs Group:</strong>
            <p class="mt-1">
              While both can contain multiple items, Sections are for larger visual blocks (like
              card containers), while Groups are for layout arrangements (like horizontal or grid layouts).
              Sections can contain Groups, and vice versa.
            </p>
          </div>
        </div>
      </div>

      <div class="mt-8 rounded-lg bg-gray-50 p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Code Example</h3>
        <div class="text-sm text-gray-800">
          <p class="mb-2">Example of defining a section in your form instance:</p>
          <pre class="bg-gray-100 p-4 rounded overflow-x-auto text-xs font-mono"><code>&#37;Instance.Element&#123;
            id: "personal-section",
            type: "section",
            content: "Personal Information",
            items: [
              &#37;Instance.Field&#123;
                id: "first_name",
                name: "first_name",
                type: "string",
                label: "First Name",
                required: true
              &#125;,
              &#37;Instance.Field&#123;
                id: "email",
                name: "email",
                type: "email",
                label: "Email",
                required: true
              &#125;
            ]
          &#125;</code></pre>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    changeset =
      socket.assigns.form_instance
      |> Changeset.create_changeset(params)
      |> Map.put(:action, :validate)

    form = to_form(changeset, as: "form")

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, form)}
  end

  @impl true
  def handle_event("submit", %{"form" => params}, socket) do
    changeset =
      socket.assigns.form_instance
      |> Changeset.create_changeset(params)
      |> Map.put(:action, :update)

    case changeset.valid? do
      true ->
        # Submit via backend
        instance = socket.assigns.form_instance
        backend_module = instance.backend.module
        backend_config = instance.backend.config

        case backend_module.submit(changeset, backend_config) do
          {:ok, result} ->
            form_data = Ecto.Changeset.apply_changes(changeset)

            {:noreply,
             socket
             |> assign(:submitted_data, form_data)
             |> put_flash(:info, result.message || "Profile saved successfully!")}

          {:error, error} ->
            {:noreply,
             socket
             |> put_flash(:error, error.message || "Failed to save profile")}
        end

      false ->
        changeset = Map.put(changeset, :action, :validate)
        form = to_form(changeset, as: "form")

        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> assign(:form, form)
         |> put_flash(:error, "Please fix the errors below")}
    end
  end
end
