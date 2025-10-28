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

  ### Usage

  1. Set the `hide_submit` option to `true` on your DynamicForm.Renderer
  2. Give your form a unique `form_id`
  3. Use `DynamicForm.submit_button/1` anywhere on the page with the matching form ID

  ### Example

      # Render the form without a submit button
      <DynamicForm.Renderer.render
        instance={@form_instance}
        form={@form}
        form_id="my-dynamic-form"
        hide_submit={true}
        phx_submit="submit"
        phx_change="validate"
      />

      # Place the submit button anywhere on the page
      <div class="sticky bottom-0 p-4 bg-white border-t">
        <DynamicForm.submit_button form="my-dynamic-form">
          Save Changes
        </DynamicForm.submit_button>
      </div>

  See `DynamicForm.CoreComponents.submit_button/1` for more details.
  """

  defdelegate submit_button(assigns), to: DynamicForm.CoreComponents
end
