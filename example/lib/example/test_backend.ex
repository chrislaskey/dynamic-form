defmodule Example.TestBackend do
  @moduledoc """
  A simple test backend for DynamicForm that just logs submissions.
  This is for demonstration purposes only.
  """

  @behaviour DynamicForm.Backend

  require Logger

  @impl DynamicForm.Backend
  def submit(changeset, _config) do
    if changeset.valid? do
      form_data = Ecto.Changeset.apply_changes(changeset)
      Logger.info("Form submitted successfully: #{inspect(form_data)}")
      {:ok, %{message: "Form submitted successfully!", data: form_data}}
    else
      {:error, %{message: "Form validation failed", errors: changeset.errors}}
    end
  end

  @impl DynamicForm.Backend
  def validate_config(_config) do
    # No config required for test backend
    :ok
  end
end
