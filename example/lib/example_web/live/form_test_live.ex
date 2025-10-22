defmodule ExampleWeb.FormTestLive do
  use ExampleWeb, :live_view

  alias DynamicForm.{Instance, Changeset}

  @impl true
  def mount(_params, _session, socket) do
    # Create a test form instance with various field types
    form_instance = create_test_form()

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
    <div class="mx-auto max-w-2xl px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">DynamicForm Renderer Test</h1>
        <p class="mt-2 text-gray-600">
          This form is rendered dynamically from a DynamicForm.Instance configuration.
        </p>
      </div>

      <div class="rounded-lg bg-white shadow-sm ring-1 ring-gray-900/5 p-6">
        <h2 class="text-xl font-semibold text-gray-900 mb-6"><%= @form_instance.name %></h2>
        <%= if @form_instance.description do %>
          <p class="text-gray-600 mb-6"><%= @form_instance.description %></p>
        <% end %>

        <DynamicForm.Renderer.render
          instance={@form_instance}
          form={@form}
          submit_text="Submit Form"
          phx_submit="submit"
          phx_change="validate"
          form_id="test-form"
        />
      </div>

      <%= if @submitted_data do %>
        <div class="mt-8 rounded-lg bg-green-50 p-6">
          <h3 class="text-lg font-semibold text-green-900 mb-4">✓ Form Submitted Successfully!</h3>
          <div class="text-sm text-green-800">
            <p class="font-semibold mb-2">Submitted Data:</p>
            <pre class="bg-green-100 p-4 rounded overflow-x-auto"><%= inspect(@submitted_data, pretty: true) %></pre>
          </div>
        </div>
      <% end %>

      <div class="mt-8 rounded-lg bg-gray-50 p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Form Configuration</h3>
        <div class="text-sm text-gray-800">
          <p class="mb-2">
            <span class="font-semibold">Number of fields:</span>
            <%= length(@form_instance.fields) %>
          </p>
          <p class="mb-4">
            <span class="font-semibold">Backend:</span>
            <%= inspect(@form_instance.backend.module) %>
          </p>
          <details class="mt-4">
            <summary class="cursor-pointer font-semibold text-gray-700 hover:text-gray-900">
              View Full Configuration
            </summary>
            <pre class="mt-2 bg-gray-100 p-4 rounded overflow-x-auto text-xs"><%= inspect(@form_instance, pretty: true) %></pre>
          </details>
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
             |> put_flash(:info, result.message || "Form submitted successfully!")}

          {:error, error} ->
            {:noreply,
             socket
             |> put_flash(:error, error.message || "Failed to submit form")}
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

  # Creates a comprehensive test form with various field types
  defp create_test_form do
    %Instance{
      id: "test-form-1",
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
