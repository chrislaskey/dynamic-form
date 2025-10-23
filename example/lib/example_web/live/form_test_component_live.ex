defmodule ExampleWeb.FormTestComponentLive do
  @moduledoc """
  Test page for the DynamicForm.RendererLive LiveComponent.

  This demonstrates all three callback patterns:
  - Pattern A: Message passing (send_messages: true)
  - Pattern B: Function callbacks (on_success/on_error)
  - Pattern C: No callbacks (self-contained)
  """

  use ExampleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    form_instance = Example.FormInstances.contact_form()

    {:ok,
     assign(socket,
       form_instance: form_instance,
       callback_mode: :function,
       last_result: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">LiveComponent Renderer Test</h1>
        <p class="mt-2 text-gray-600">
          This form uses the
          <code class="bg-gray-100 px-2 py-1 rounded">DynamicForm.RendererLive</code>
          LiveComponent with automatic state management.
        </p>
      </div>
      
    <!-- Mode Selector -->
      <div class="mb-6 p-4 bg-gray-50 rounded-lg">
        <h3 class="font-semibold mb-3 text-gray-900">Callback Mode:</h3>
        <p class="text-sm text-gray-600 mb-3">
          Switch between different callback patterns to see how the component behaves.
        </p>
        <.form for={%{}} phx-change="change_mode">
          <select
            name="mode"
            class="rounded-md border-gray-300 shadow-sm focus:border-indigo-600 focus:ring-indigo-600"
          >
            <option value="function" selected={@callback_mode == :function}>
              Function Callbacks (on_success/on_error)
            </option>
            <option value="message" selected={@callback_mode == :message}>
              Message Passing (send_messages: true)
            </option>
            <option value="none" selected={@callback_mode == :none}>
              No Callbacks (self-contained)
            </option>
          </select>
        </.form>

        <div class="mt-3 text-sm">
          <p class="font-medium text-gray-700">Current mode:</p>
          <code class="block mt-1 bg-white p-2 rounded">{describe_mode(@callback_mode)}</code>
        </div>
      </div>
      
    <!-- LiveComponent with dynamic callbacks -->
      <div class="rounded-lg bg-white shadow-sm ring-1 ring-gray-900/5 p-6">
        <%= if @callback_mode == :function do %>
          <.live_component
            module={DynamicForm.RendererLive}
            id="contact-form"
            instance={@form_instance}
            on_success={&handle_success/2}
            on_error={&handle_error/2}
            submit_text="Submit with Function Callbacks"
          />
        <% end %>

        <%= if @callback_mode == :message do %>
          <.live_component
            module={DynamicForm.RendererLive}
            id="contact-form"
            instance={@form_instance}
            send_messages={true}
            submit_text="Submit with Messages"
          />
        <% end %>

        <%= if @callback_mode == :none do %>
          <.live_component
            module={DynamicForm.RendererLive}
            id="contact-form"
            instance={@form_instance}
            submit_text="Submit (No Callbacks)"
          />
        <% end %>
      </div>

      <%= if @last_result do %>
        <div class="mt-8 rounded-lg bg-green-50 p-6">
          <h3 class="text-lg font-semibold text-green-900 mb-4">Last Submission Result</h3>
          <div class="text-sm text-green-800">
            <pre class="bg-green-100 p-4 rounded overflow-x-auto"><%= inspect(@last_result, pretty: true) %></pre>
          </div>
        </div>
      <% end %>
      
    <!-- Documentation -->
      <div class="mt-8 rounded-lg bg-gray-50 p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">About Callback Patterns</h3>
        <div class="space-y-4 text-sm text-gray-700">
          <div>
            <h4 class="font-semibold">Function Callbacks</h4>
            <p class="mt-1">
              Provides <code class="bg-white px-1 rounded">on_success</code>
              and <code class="bg-white px-1 rounded">on_error</code>
              callbacks that receive
              the socket and result. Allows direct socket manipulation like navigation and flash messages.
            </p>
          </div>
          <div>
            <h4 class="font-semibold">Message Passing</h4>
            <p class="mt-1">
              Sends messages like <code class="bg-white px-1 rounded">:dynamic_form_success</code>
              and <code class="bg-white px-1 rounded">:dynamic_form_error</code>
              to the parent LiveView via <code class="bg-white px-1 rounded">handle_info/2</code>.
            </p>
          </div>
          <div>
            <h4 class="font-semibold">No Callbacks</h4>
            <p class="mt-1">
              The component handles everything internally. Useful for simple forms that don't
              need custom behavior after submission.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Function callback handlers (Pattern B)
  defp handle_success(socket, result) do
    socket
    |> put_flash(:info, "✓ Function Callback: #{result.message}")
    |> assign(:last_result, result)
  end

  defp handle_error(socket, error) do
    put_flash(socket, :error, "✗ Function Callback: #{error.message}")
  end

  # Message handlers (Pattern A)
  @impl true
  def handle_info({:dynamic_form_success, _id, result}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "✓ Message: #{result.message}")
     |> assign(:last_result, result)}
  end

  @impl true
  def handle_info({:dynamic_form_error, _id, error}, socket) do
    {:noreply, put_flash(socket, :error, "✗ Message: #{error.message}")}
  end

  # Mode switcher
  @impl true
  def handle_event("change_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :callback_mode, String.to_atom(mode))}
  end

  defp describe_mode(:function) do
    """
    on_success={&handle_success/2}
    on_error={&handle_error/2}
    """
  end

  defp describe_mode(:message) do
    """
    send_messages={true}
    """
  end

  defp describe_mode(:none) do
    """
    (no callback attributes)
    """
  end
end
