defmodule DynamicForm.Backend do
  @moduledoc """
  Behaviour for form submission backends.

  Backend modules handle form submission after validation. Each backend implements
  how to process the validated form data.

  The function to call on the backend module is configured in the Instance.Backend struct,
  allowing you to use different function names (e.g., :submit, :process, :handle, etc.).

  ## Example

      defmodule MyApp.EmailBackend do
        @behaviour DynamicForm.Backend

        # This function can be named anything - it's specified in the Backend config
        def submit(form_data, config: backend_config) do
          recipient_email = Keyword.fetch!(backend_config, :recipient_email)
          subject = Keyword.fetch!(backend_config, :subject)

          case send_email(recipient_email, subject, form_data) do
            {:ok, _result} ->
              {:ok, %{message: "Form submitted successfully via email", data: form_data}}
            {:error, reason} ->
              {:error, %{message: "Failed to send email: \#{reason}"}}
          end
        end

        @impl DynamicForm.Backend
        def validate_config(config) do
          required_keys = [:recipient_email, :subject]

          case Enum.find(required_keys, &is_nil(config[&1])) do
            nil -> :ok
            missing_key -> {:error, "Missing required config: \#{missing_key}"}
          end
        end

        defp send_email(recipient, subject, form_data) do
          # Implementation using your email service
          {:ok, "email_sent"}
        end
      end

      # Usage in Instance configuration:
      backend: %DynamicForm.Instance.Backend{
        module: MyApp.EmailBackend,
        function: :submit,  # Can be any function name
        config: [
          recipient_email: "admin@example.com",
          subject: "New Form Submission"
        ]
      }
  """

  @doc """
  Submits the form data using the backend's implementation.

  This callback documents the expected signature for backend submission functions.
  The actual function name is configurable via the Instance.Backend struct.

  Receives the form data (as a map) and backend-specific configuration as a keyword list.
  Returns `{:ok, result}` on success or `{:error, reason}` on failure.

  The result map should include:
  - `:message` - A success/error message
  - `:data` - The submitted form data (optional but recommended)

  ## Parameters
    * `form_data` - Map of the submitted form data
    * `config` - Keyword list of backend-specific configuration (passed as `config: backend_config`)

  ## Returns
    * `{:ok, result}` - Where result is a map with at least `:message` and optionally `:data`
    * `{:error, error}` - Where error is a map with at least `:message`
  """
  @callback submit(form_data :: map(), config :: Keyword.t()) ::
              {:ok, map()} | {:error, map()}

  @doc """
  Validates the backend configuration.

  Returns `:ok` if configuration is valid, or `{:error, message}` if invalid.
  """
  @callback validate_config(config :: Keyword.t()) :: :ok | {:error, String.t()}
end
