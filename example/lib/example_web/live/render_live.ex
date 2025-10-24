defmodule ExampleWeb.RenderLive do
  @moduledoc """
  Demo page showcasing DynamicForm in both create and edit modes.

  Features:
  - Mode selector to switch between create and edit
  - Pre-populated data in edit mode
  - Display of submitted values on success
  """

  use ExampleWeb, :live_view

  alias DynamicForm.Instance

  @impl true
  def mount(_params, _session, socket) do
    create_form = Example.FormInstances.contact_form()
    edit_form = disable_email_field(create_form)

    {:ok,
     assign(socket,
       create_form: create_form,
       edit_form: edit_form,
       mode: :create,
       last_submission: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Create vs Edit Mode Demo</h1>
        <p class="mt-2 text-gray-600">
          This demo shows how the same form can be used to both create new records and edit existing ones.
        </p>
      </div>
      
    <!-- Mode Selector -->
      <div class="mb-6 p-4 bg-gray-50 rounded-lg">
        <h3 class="font-semibold mb-3 text-gray-900">Test Mode:</h3>
        <.form for={%{}} phx-change="change_mode">
          <select
            name="mode"
            class="rounded-md border-gray-300 shadow-sm focus:border-indigo-600 focus:ring-indigo-600"
          >
            <option value="create" selected={@mode == :create}>
              Create Mode - Empty form for new records
            </option>
            <option value="edit" selected={@mode == :edit}>
              Edit Mode - Pre-populated with existing data
            </option>
          </select>
        </.form>

        <div class="mt-3 p-3 bg-white rounded border border-gray-200">
          <p class="text-sm font-medium text-gray-700">
            Current mode: <code class="text-indigo-600">{@mode}</code>
          </p>
          <%= if @mode == :edit do %>
            <p class="text-sm text-gray-600 mt-2">
              Form is pre-populated with sample data. Some fields (ID, Email) are disabled to prevent changes.
            </p>
          <% else %>
            <p class="text-sm text-gray-600 mt-2">
              Form starts empty, ready to create a new contact record.
            </p>
          <% end %>
        </div>
      </div>
      
    <!-- The Form -->
      <div class="rounded-lg bg-white shadow-sm ring-1 ring-gray-900/5 p-6">
        <%= if @mode == :create do %>
          <h2 class="text-xl font-semibold text-gray-900 mb-2">{@create_form.name}</h2>
          <%= if @create_form.description do %>
            <p class="text-gray-600 mb-6">{@create_form.description}</p>
          <% end %>

          <.live_component
            module={DynamicForm.RendererLive}
            id="contact-form"
            instance={@create_form}
            params={%{}}
            send_messages={true}
            submit_text="Create Contact"
          />
        <% end %>

        <%= if @mode == :edit do %>
          <h2 class="text-xl font-semibold text-gray-900 mb-2">{@edit_form.name}</h2>
          <%= if @edit_form.description do %>
            <p class="text-gray-600 mb-6">{@edit_form.description}</p>
          <% end %>

          <.live_component
            module={DynamicForm.RendererLive}
            id="contact-form-edit"
            instance={@edit_form}
            params={sample_edit_data()}
            send_messages={true}
            submit_text="Update Contact"
          />
        <% end %>
      </div>
      
    <!-- Submission Result Display -->
      <%= if @last_submission do %>
        <div class="mt-8 rounded-lg bg-green-50 p-6">
          <h3 class="text-lg font-semibold text-green-900 mb-4">
            ✓ Form Submitted Successfully!
          </h3>
          <div class="space-y-4">
            <div>
              <p class="text-sm font-semibold text-green-800 mb-2">Mode:</p>
              <div class="bg-green-100 p-3 rounded">
                <code class="text-sm text-green-900">{@last_submission.mode}</code>
              </div>
            </div>
            <div>
              <p class="text-sm font-semibold text-green-800 mb-2">Submitted Values:</p>
              <div class="bg-green-100 p-4 rounded overflow-x-auto">
                <pre class="text-xs text-green-900"><%= inspect(@last_submission.data, pretty: true) %></pre>
              </div>
            </div>
          </div>
        </div>
      <% end %>
      
    <!-- Documentation -->
      <div class="mt-8 rounded-lg bg-gray-50 p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">How It Works</h3>
        <div class="space-y-3 text-sm text-gray-700">
          <div>
            <h4 class="font-semibold">Create Mode</h4>
            <p class="mt-1">
              The form is initialized with empty params:
              <code class="bg-white px-2 py-1 rounded">params={inspect(%{})}</code>
            </p>
          </div>
          <div>
            <h4 class="font-semibold">Edit Mode</h4>
            <p class="mt-1">
              The form is initialized with existing data:
              <code class="bg-white px-2 py-1 rounded">
                params={inspect(%{"name" => "...", "email" => "..."})}
              </code>
            </p>
            <p class="mt-1 text-xs text-gray-600">
              The same DynamicForm.RendererLive component handles both cases automatically.
              In edit mode, certain fields (like ID and Email) are marked as
              <code class="bg-white px-1 rounded">disabled: true</code>
              to prevent modification while still displaying the values.
            </p>
          </div>
          <div>
            <h4 class="font-semibold">Implementation</h4>
            <p class="mt-1">
              Both modes use the same
              <code class="bg-white px-2 py-1 rounded">DynamicForm.RendererLive</code>
              component,
              just with different <code class="bg-white px-2 py-1 rounded">:params</code>
              values. The component
              automatically handles the changeset creation and validation.
            </p>
            <p class="mt-1 text-xs text-gray-600">
              This example uses message passing (<code class="bg-white px-1 rounded">send_messages: true</code>)
              to receive form submission results via <code class="bg-white px-1 rounded">handle_info/2</code>,
              allowing the parent LiveView to update state and display the submitted data.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Handle success message from the form component
  @impl true
  def handle_info({:dynamic_form_success, _id, result}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "✓ #{result.message}")
     |> assign(:last_submission, %{
       mode: socket.assigns.mode,
       data: result.data,
       timestamp: DateTime.utc_now()
     })}
  end

  # Handle error message from the form component
  @impl true
  def handle_info({:dynamic_form_error, _id, error}, socket) do
    {:noreply, put_flash(socket, :error, "✗ #{error.message}")}
  end

  # Handle mode changes
  @impl true
  def handle_event("change_mode", %{"mode" => mode}, socket) do
    {:noreply,
     socket
     |> assign(:mode, String.to_atom(mode))
     |> assign(:last_submission, nil)}
  end

  # Sample data for edit mode
  defp sample_edit_data do
    %{
      "id" => "bc7a4a1f-0a04-4846-939f-6156e12ccf06",
      "name" => "Jane Smith",
      "email" => "jane.smith@example.com",
      "phone" => "(555) 987-6543",
      "preferred_contact" => "email",
      "subject" => "support",
      "message" =>
        "I'm having some issues with the platform and need assistance. The dashboard isn't loading properly.",
      "priority" => "8",
      "subscribe" => "true",
      "newsletter_frequency" => "weekly"
    }
  end

  # Transform function to add disabled: true to the email field
  defp disable_email_field(%Instance{} = instance) do
    %{instance | items: transform_items(instance.items)}
  end

  # Transform items list, handling both Fields and Elements
  defp transform_items(items) when is_list(items) do
    Enum.map(items, &transform_item/1)
  end

  # Transform a single Field - add disabled: true if it's the email field
  defp transform_item(%Instance.Field{id: "email"} = field) do
    %{field | disabled: true}
  end

  # Transform a single Field - leave other fields unchanged
  defp transform_item(%Instance.Field{} = field) do
    field
  end

  # Transform an Element - recursively transform nested items if they exist
  defp transform_item(%Instance.Element{items: items} = element) when is_list(items) do
    %{element | items: transform_items(items)}
  end

  # Transform an Element without nested items - leave unchanged
  defp transform_item(%Instance.Element{} = element) do
    element
  end
end
