defmodule ExampleWeb.PaymentFormLive do
  use ExampleWeb, :live_view

  alias DynamicForm.Changeset

  @impl true
  def mount(_params, _session, socket) do
    # Get payment form instance
    form_instance = Example.FormInstances.payment_form()

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
        <h1 class="text-3xl font-bold text-gray-900">Payment Form - Conditional Visibility Demo</h1>
        <p class="mt-2 text-gray-600">
          This form demonstrates conditional field visibility. Select different payment methods to see how the form dynamically shows and hides relevant fields.
        </p>
      </div>

      <div class="rounded-lg bg-white shadow-sm ring-1 ring-gray-900/5 p-6">
        <h2 class="text-xl font-semibold text-gray-900 mb-6">{@form_instance.name}</h2>
        <%= if @form_instance.description do %>
          <p class="text-gray-600 mb-6">{@form_instance.description}</p>
        <% end %>

        <DynamicForm.Renderer.render
          instance={@form_instance}
          form={@form}
          submit_text="Process Payment"
          phx_submit="submit"
          phx_change="validate"
          form_id="payment-form"
        />
      </div>

      <%= if @submitted_data do %>
        <div class="mt-8 rounded-lg bg-green-50 p-6">
          <h3 class="text-lg font-semibold text-green-900 mb-4">✓ Payment Submitted Successfully!</h3>
          <div class="text-sm text-green-800">
            <p class="font-semibold mb-2">Submitted Data:</p>
            <pre class="bg-green-100 p-4 rounded overflow-x-auto"><%= inspect(@submitted_data, pretty: true) %></pre>
          </div>
        </div>
      <% end %>

      <div class="mt-8 rounded-lg bg-blue-50 p-6">
        <h3 class="text-lg font-semibold text-blue-900 mb-4">💡 How It Works</h3>
        <div class="text-sm text-blue-800 space-y-2">
          <p>
            <strong>Try it:</strong>
            Change the "Payment Method" dropdown to see different fields appear:
          </p>
          <ul class="list-disc list-inside ml-4 space-y-1">
            <li><strong>Credit Card</strong> - Shows card number, expiry date, and CVV fields</li>
            <li><strong>Bank Transfer</strong> - Shows account number and routing number fields</li>
            <li><strong>PayPal</strong> - Shows PayPal email field</li>
          </ul>
          <p class="mt-4">
            Each conditional field has a <code class="bg-blue-100 px-1 rounded">visible_when</code>
            attribute that checks the payment method value.
          </p>
        </div>
      </div>

      <div class="mt-8 rounded-lg bg-gray-50 p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Form Configuration</h3>
        <div class="text-sm text-gray-800">
          <p class="mb-2">
            <span class="font-semibold">Total fields:</span>
            {length(@form_instance.fields)}
          </p>
          <p class="mb-2">
            <span class="font-semibold">Conditional fields:</span>
            {Enum.count(@form_instance.fields, fn f -> f.visible_when != nil end)}
          </p>
          <p class="mb-4">
            <span class="font-semibold">Backend:</span>
            {inspect(@form_instance.backend.module)}
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
             |> put_flash(:info, result.message || "Payment submitted successfully!")}

          {:error, error} ->
            {:noreply,
             socket
             |> put_flash(:error, error.message || "Failed to submit payment")}
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
