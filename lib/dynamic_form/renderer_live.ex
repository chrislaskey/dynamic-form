defmodule DynamicForm.RendererLive do
  @moduledoc """
  A LiveComponent version of the DynamicForm renderer with automatic state management.

  This component handles form state, validation, and backend submission automatically,
  offering three configurable callback patterns:

  ## Attributes

  ### Required

    * `:id` - Component ID (string, required by LiveComponent)
    * `:instance` - DynamicForm.Instance struct containing form configuration

  ### Optional

    * `:params` - Initial form params for edit mode (map, default: `%{}`)
    * `:form_name` - Form namespace for params (string, default: `"dynamic_form"`)
    * `:submit_text` - Submit button text (string, default: `nil`)
    * `:send_messages` - Whether to send messages to parent LiveView (boolean, default: `false`)
    * `:on_success` - Success callback function `(socket, result -> socket)` (function, default: `nil`)
    * `:on_error` - Error callback function `(socket, error -> socket)` (function, default: `nil`)

  ## Pattern A: Message Passing

  Component sends messages to parent LiveView:

      <.live_component
        module={DynamicForm.RendererLive}
        id="contact-form"
        instance={@form_instance}
        send_messages={true}
      />

      def handle_info({:dynamic_form_success, _id, result}, socket) do
        {:noreply, put_flash(socket, :info, result.message)}
      end

  ## Pattern B: Function Callbacks

  Direct function calls with socket operations:

      <.live_component
        module={DynamicForm.RendererLive}
        id="contact-form"
        instance={@form_instance}
        on_success={&handle_success/2}
        on_error={&handle_error/2}
      />

      defp handle_success(socket, result) do
        socket
        |> put_flash(:info, "Success!")
        |> push_navigate(to: ~p"/thank-you")
      end

  ## Pattern C: No Callbacks

  Component handles everything internally:

      <.live_component
        module={DynamicForm.RendererLive}
        id="contact-form"
        instance={@form_instance}
      />

  ## Edit Mode

  To pre-populate the form with existing data:

      <.live_component
        module={DynamicForm.RendererLive}
        id="user-profile"
        instance={@form_instance}
        params={%{"name" => "John", "email" => "john@example.com"}}
        form_name="user_profile"
        send_messages={true}
      />
  """

  use Phoenix.LiveComponent
  alias DynamicForm.{Renderer, Changeset}

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    form_name = Map.get(assigns, :form_name, "dynamic_form")
    params = Map.get(assigns, :params, %{})
    changeset = Changeset.create_changeset(assigns.instance, params)
    form = to_form(changeset, as: form_name)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, form)
     |> assign(:form_name, form_name)
     |> assign(:submitting, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Renderer.render
        instance={@instance}
        form={@form}
        submit_text={@submit_text}
        phx_submit="submit"
        phx_change="validate"
        target={@myself}
        form_id={"#{@id}-form"}
        disabled={@submitting}
      />
    </div>
    """
  end

  @impl true
  def handle_event("validate", params, socket) do
    form_params = Map.get(params, socket.assigns.form_name, %{})

    changeset =
      socket.assigns.instance
      |> Changeset.create_changeset(form_params)
      |> Map.put(:action, socket.assigns.changeset.action)

    form = to_form(changeset, as: socket.assigns.form_name)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, form)}
  end

  @impl true
  def handle_event("submit", params, socket) do
    form_params = Map.get(params, socket.assigns.form_name, %{})

    changeset =
      socket.assigns.instance
      |> Changeset.create_changeset(form_params)
      |> Map.put(:action, :updated)

    if changeset.valid? do
      socket = assign(socket, :submitting, true)

      # Submit via backend
      instance = socket.assigns.instance
      backend_module = instance.backend.module
      backend_config = instance.backend.config

      case backend_module.submit(changeset, backend_config) do
        {:ok, result} ->
          socket = handle_success(socket, result)
          {:noreply, assign(socket, :submitting, false)}

        {:error, error} ->
          socket = handle_error(socket, error)
          {:noreply, assign(socket, :submitting, false)}
      end
    else
      changeset = Map.put(changeset, :action, :validate)
      form = to_form(changeset, as: socket.assigns.form_name)

      {:noreply,
       socket
       |> assign(:changeset, changeset)
       |> assign(:form, form)}
    end
  end

  defp handle_success(socket, result) do
    # Pattern B: Function callback
    socket =
      if callback = socket.assigns[:on_success] do
        callback.(socket, result)
      else
        socket
      end

    # Pattern A: Message passing
    if socket.assigns[:send_messages] do
      send(self(), {:dynamic_form_success, socket.assigns.id, result})
    end

    socket
  end

  defp handle_error(socket, error) do
    # Pattern B: Function callback
    socket =
      if callback = socket.assigns[:on_error] do
        callback.(socket, error)
      else
        socket
      end

    # Pattern A: Message passing
    if socket.assigns[:send_messages] do
      send(self(), {:dynamic_form_error, socket.assigns.id, error})
    end

    socket
  end
end
