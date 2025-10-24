defmodule Example.TestBackend do
  @moduledoc """
  A simple test backend for DynamicForm that just logs submissions.
  This is for demonstration purposes only.
  """

  @behaviour DynamicForm.Backend

  require Logger

  @impl DynamicForm.Backend
  def submit(data, _options) do
    Logger.info("Form submitted successfully: #{inspect(data)}")

    {:ok, %{message: "Form submitted successfully!", data: data}}
  end

  @impl DynamicForm.Backend
  def validate_config(_config) do
    # No config required for test backend
    :ok
  end
end
