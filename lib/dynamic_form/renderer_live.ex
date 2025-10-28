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
    * `:hide_submit` - Whether to hide the submit button (boolean, default: `false`)
    * `:gettext` - Gettext backend module for translations (atom, default: `DynamicForm.Gettext`)

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

  ### Disabled Fields

  Fields can be marked as `disabled: true` in the form instance configuration.
  Disabled fields are displayed but cannot be edited by the user.

  **Important**: Disabled HTML fields are not submitted by browsers, so their values
  are automatically preserved by merging the initial `:params` with form submissions.
  This ensures disabled field values remain in the changeset throughout validation
  and submission.

  ### External Submit Button

  You can place a submit button outside the form element by using the `hide_submit`
  option and `DynamicForm.RendererLive.submit_button/1`:

      <DynamicForm.RendererLive.submit_button form="my-form-form">
        Save Changes
      </DynamicForm.RendererLive.submit_button>

      <.live_component
        module={DynamicForm.RendererLive}
        id="my-form"
        instance={@form_instance}
        hide_submit={true}
        send_messages={true}
      />

  Note: The form ID is automatically generated as `"\#{id}-form"`, so if your component
  ID is "my-form", the form element ID will be "my-form-form".

  ## Backend Function

  The backend function specified in the form instance is called with the following signature:

      backend_function(data, opts)

  Where:
    * `data` - The validated form data (Ecto.Changeset.apply_changes/1 result)
    * `opts` - Keyword list containing:
      - `:config` - The backend configuration from the form instance
      - `:changeset` - The validated changeset

  The backend function can return:
    * `{:ok, result}` - Success, where result is passed to success handlers
    * `{:error, %Ecto.Changeset{}}` - Validation errors to display on the form
    * `{:error, error}` - General error, passed to error handlers

  Example backend function that adds custom errors:

      def process_form(data, opts) do
        config = Keyword.get(opts, :config)
        changeset = Keyword.get(opts, :changeset)

        if email_already_exists?(data.email) do
          {:error, Ecto.Changeset.add_error(changeset, :email, "already taken")}
        else
          save_to_database(data, config)
        end
      end

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
    gettext = Map.get(assigns, :gettext, DynamicForm.Gettext)
    changeset = Changeset.create_changeset(assigns.instance, initial_params)
    form = to_form(changeset, as: form_name)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, form)
     |> assign(:form_name, form_name)
     |> assign(:initial_params, initial_params)
     |> assign(:gettext, gettext)
     |> assign(:submitting, false)}
  end

  @impl true
  def render(assigns) do
    hide_submit = Map.get(assigns, :hide_submit, false)
    assigns = assign(assigns, :hide_submit, hide_submit)

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
        hide_submit={@hide_submit}
        gettext={@gettext}
      />
    </div>
    """
  end

  @impl true
  def handle_event("validate", params, socket) do
    form_params = Map.get(params, socket.assigns.form_name, %{})
    merged_params = merge_data(socket.assigns.initial_params, form_params)

    changeset =
      socket.assigns.instance
      |> Changeset.create_changeset(merged_params)
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
    merged_params = merge_data(socket.assigns.initial_params, form_params)

    changeset =
      socket.assigns.instance
      |> Changeset.create_changeset(merged_params)
      |> Map.put(:action, :updated)

    if changeset.valid? do
      data = Ecto.Changeset.apply_changes(changeset)

      # Submit via backend
      instance = socket.assigns.instance
      backend_module = instance.backend.module
      backend_function = instance.backend.function
      backend_config = instance.backend.config

      socket = assign(socket, :submitting, true)
      meta = [config: backend_config, changeset: changeset]

      case apply(backend_module, backend_function, [data, meta]) do
        {:ok, result} ->
          socket = handle_success(socket, result)
          {:noreply, assign(socket, :submitting, false)}

        {:error, %Ecto.Changeset{} = changeset} ->
          changeset = Map.put(changeset, :action, :validate)
          form = to_form(changeset, as: socket.assigns.form_name)

          {:noreply,
           socket
           |> assign(:changeset, changeset)
           |> assign(:form, form)}

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

  defp merge_data(initial_params, changeset_data) do
    # Merging data helps solve a few different scenarios:
    #
    # - Editing an existing record that has additional fields like `id` we want
    #   to preserve. Technically this can be done in the form instance by
    #   including a hidden `id` field but it's easy to miss. Especially if
    #   using a WYSIWYG editor and are unfamiliar with forms.
    #
    # - Handling disabled fields. Disabled inputs aren't included in the changeset
    #   which can cause disabled field values to disappear.
    #
    initial = recursively_convert_to_string_keys(initial_params)
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

  # Public API

  @doc """
  Renders a submit button that can be placed outside a form element.

  Uses the HTML `form` attribute to associate the button with a form by its ID.
  This allows the submit button to be placed anywhere on the page, not just
  inside the form element.

  When using with `DynamicForm.RendererLive`, the form ID is automatically
  generated as `"\#{component_id}-form"`. For example, if your LiveComponent
  has `id="my-form"`, the form element ID will be `"my-form-form"`.

  ## Examples

      # LiveComponent with external submit button
      <DynamicForm.RendererLive.submit_button form="contact-form-form">
        Submit Contact Form
      </DynamicForm.RendererLive.submit_button>

      <.live_component
        module={DynamicForm.RendererLive}
        id="contact-form"
        instance={@form_instance}
        hide_submit={true}
      />

      # In a modal footer
      <.modal id="edit-modal">
        <.live_component
          module={DynamicForm.RendererLive}
          id="user-profile"
          instance={@form_instance}
          hide_submit={true}
        />
        <:actions>
          <DynamicForm.RendererLive.submit_button form="user-profile-form">
            Save Profile
          </DynamicForm.RendererLive.submit_button>
        </:actions>
      </.modal>

  ## Attributes

    * `form` - The ID of the form element to submit (required)
    * `class` - Additional CSS classes to apply to the button
    * `disabled` - Whether the button is disabled
  """
  use Phoenix.Component

  attr(:form, :string, required: true, doc: "The ID of the form element to submit")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:disabled, :boolean, default: false, doc: "Whether the button is disabled")
  attr(:rest, :global, include: ~w(name value))

  slot(:inner_block, required: true)

  def submit_button(assigns) do
    ~H"""
    <button
      type="submit"
      form={@form}
      disabled={@disabled}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
