defmodule DynamicForm.RendererLive do
  @moduledoc """
  A LiveComponent version of the DynamicForm renderer with automatic state management.

  This component handles form state, validation, and backend submission automatically,
  communicating with the parent LiveView via message passing.

  ## Attributes

  ### Required

    * `:id` - Component ID (string, required by LiveComponent)
    * `:instance` - DynamicForm.Instance struct containing form configuration

  ### Optional

    * `:params` - Initial form params for edit mode (map, default: `%{}`)
    * `:form_name` - Form namespace for params (string, default: `"dynamic_form"`)
    * `:submit_text` - Submit button text (string, default: `nil`)
    * `:send_messages` - Whether to send messages to parent LiveView (boolean, default: `false`)

  ## Usage

  ### Basic Usage with Message Passing

  Component sends messages to parent LiveView on form submission:

      <.live_component
        module={DynamicForm.RendererLive}
        id="contact-form"
        instance={@form_instance}
        send_messages={true}
      />

      def handle_info({:dynamic_form_success, _id, result}, socket) do
        {:noreply, put_flash(socket, :info, result.message)}
      end

      def handle_info({:dynamic_form_error, _id, error}, socket) do
        {:noreply, put_flash(socket, :error, error.message)}
      end

  ### No Messages (Self-Contained)

  Component handles everything internally:

      <.live_component
        module={DynamicForm.RendererLive}
        id="contact-form"
        instance={@form_instance}
      />

  ### Edit Mode

  Pre-populate the form with existing data:

      <.live_component
        module={DynamicForm.RendererLive}
        id="user-profile"
        instance={@form_instance}
        params={%{"name" => "John", "email" => "john@example.com"}}
        form_name="user_profile"
        send_messages={true}
      />

  ## Messages

  When `send_messages` is `true`, the component sends these messages to the parent LiveView:

    * `{:dynamic_form_success, component_id, result}` - Sent when form submission succeeds
      - `component_id` - The component's ID
      - `result` - Map containing `:message`, `:changeset`, and `:data` from the backend

    * `{:dynamic_form_error, component_id, error}` - Sent when form submission fails
      - `component_id` - The component's ID
      - `error` - Map containing `:message` and any other error details from the backend
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
    initial_params = Map.get(assigns, :params, %{})
    changeset = Changeset.create_changeset(assigns.instance, initial_params)
    form = to_form(changeset, as: form_name)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, form)
     |> assign(:form_name, form_name)
     |> assign(:initial_params, initial_params)
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

      changeset_data = Ecto.Changeset.apply_changes(changeset)
      initial_data = socket.assigns.initial_params
      data = merge_data(initial_data, changeset_data)

      case backend_module.submit(data, config: backend_config) do
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

  # Helpers - Data

  defp merge_data(initial_data, changeset_data) do
    initial = recursively_convert_to_string_keys(initial_data)
    changeset = recursively_convert_to_string_keys(changeset_data)

    Map.merge(initial, changeset)
  end

  defp recursively_convert_to_string_keys(%Decimal{} = value), do: value

  defp recursively_convert_to_string_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      string_key = to_string(key)
      converted_value = recursively_convert_to_string_keys(value)

      {string_key, converted_value}
    end)
  end

  defp recursively_convert_to_string_keys(list) when is_list(list) do
    Enum.map(list, &recursively_convert_to_string_keys/1)
  end

  defp recursively_convert_to_string_keys(value), do: value

  # Helpers - Handlers

  defp handle_success(socket, result) do
    # Send message to parent LiveView if requested
    if socket.assigns[:send_messages] do
      send(self(), {:dynamic_form_success, socket.assigns.id, result})
    end

    socket
  end

  defp handle_error(socket, error) do
    # Send message to parent LiveView if requested
    if socket.assigns[:send_messages] do
      send(self(), {:dynamic_form_error, socket.assigns.id, error})
    end

    socket
  end
end
