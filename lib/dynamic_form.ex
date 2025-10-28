defmodule DynamicForm do
  @moduledoc """
  DynamicForm - A Phoenix LiveView library for creating dynamic forms with full
  backend validation using changesets and calls to backend functions. Also
  supports building forms through a WYSIWYG interface.

  This library enables users to build forms dynamically through a visual interface,
  then render those forms using standard Phoenix LiveView patterns with robust
  validation and backend integration.

  ## External Submit Buttons

  DynamicForm supports placing submit buttons outside of the form element using
  the HTML `form` attribute. This is useful for:

  - Placing submit buttons in modal footers
  - Creating sticky footers with submit buttons
  - Multi-step forms with navigation controls
  - Complex layouts where the submit button needs to be separate

  ### Usage with RendererLive (Recommended)

  When using `DynamicForm.RendererLive` (LiveComponent):

  1. Set `hide_submit={true}` on your LiveComponent
  2. Use `DynamicForm.submit_button/1` with the form ID `"\#{component_id}-form"`

  Example:

      # External submit button
      <DynamicForm.submit_button form="contact-form-form">
        Submit
      </DynamicForm.submit_button>

      # LiveComponent (id "contact-form" generates form ID "contact-form-form")
      <.live_component
        module={DynamicForm.RendererLive}
        id="contact-form"
        instance={@form_instance}
        hide_submit={true}
      />

  ### Usage with Renderer (Functional Component)

  When using `DynamicForm.Renderer.render/1`:

  1. Set `hide_submit={true}` and provide a custom `form_id`
  2. Use `DynamicForm.submit_button/1` with that `form_id`

  Example:

      # External submit button
      <DynamicForm.submit_button form="my-form">
        Save
      </DynamicForm.submit_button>

      # Renderer with custom form_id
      <DynamicForm.Renderer.render
        instance={@form_instance}
        form={@form}
        form_id="my-form"
        hide_submit={true}
        phx_submit="submit"
        phx_change="validate"
      />

  See `DynamicForm.RendererLive.submit_button/1` for more details.
  """

  defdelegate submit_button(assigns), to: DynamicForm.RendererLive
end
