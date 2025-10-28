defmodule ExampleWeb.SectionFormLive do
  use ExampleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Get section form instance
    form_instance = Example.FormInstances.section_form()

    {:ok,
     socket
     |> assign(:form_instance, form_instance)
     |> assign(:submitted_data, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Section Element Demo</h1>
        <p class="mt-2 text-gray-600">
          This form demonstrates the new Section element for organizing form contents.
        </p>
        <p class="mt-2 text-sm text-indigo-600">
          <strong>New:</strong>
          This form uses an external submit button (shown below) instead of a button inside the form.
        </p>
      </div>

      <%!-- External submit button at the top --%>
      <div class="mb-6 flex justify-end">
        <DynamicForm.submit_button form="section-form-form" class="shadow-lg">
          💾 Save Profile
        </DynamicForm.submit_button>
      </div>

      <div class="rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5 p-6">
        <.live_component
          module={DynamicForm.RendererLive}
          id="section-form"
          instance={@form_instance}
          hide_submit={true}
          send_messages={true}
          submit_text="Save Profile"
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
            <strong>✨ External Submit Button:</strong>
            <p class="mt-1">
              This form demonstrates the new external submit button feature. The submit button
              at the top of the page is connected to the form using the HTML <code>form</code>
              attribute, allowing you to place submit buttons anywhere on the page - not just
              inside the form. Perfect for sticky footers, modal headers, or complex layouts!
            </p>
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
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Code Examples</h3>
        <div class="text-sm text-gray-800 space-y-4">
          <div>
            <p class="mb-2 font-semibold">Using an External Submit Button with LiveComponent:</p>
            <pre class="bg-gray-100 p-4 rounded overflow-x-auto text-xs font-mono"><code>&lt;!-- External submit button anywhere on the page --&gt;
              &lt;!-- Note: form ID is "&#123;id&#125;-form", so "section-form" becomes "section-form-form" --&gt;
              &lt;DynamicForm.submit_button form="section-form-form"&gt;
                Save Profile
              &lt;/DynamicForm.submit_button&gt;

              &lt;!-- LiveComponent with hide_submit set to true --&gt;
              &lt;.live_component
                module=&#123;DynamicForm.RendererLive&#125;
                id="section-form"
                instance=&#123;@form_instance&#125;
                hide_submit=&#123;true&#125;
                send_messages=&#123;true&#125;
              /&gt;</code></pre>
          </div>

          <div>
            <p class="mb-2 font-semibold">Example of defining a section in your form instance:</p>
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
    </div>
    """
  end

  # Handle messages from RendererLive component
  @impl true
  def handle_info({:dynamic_form_success, _id, result}, socket) do
    {:noreply,
     socket
     |> assign(:submitted_data, result.data)
     |> put_flash(:info, result.message || "Profile saved successfully!")}
  end

  @impl true
  def handle_info({:dynamic_form_error, _id, error}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, error.message || "Failed to save profile")}
  end
end
