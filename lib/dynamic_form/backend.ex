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

  **Important**: This function is called on every form submission, regardless of
  validation state. Check `changeset.valid?` to determine if built-in validations passed.

  ## Parameters
    * `form_data` - Map of the submitted form data (result of `Ecto.Changeset.apply_changes/1`)
    * `changeset` - The Ecto.Changeset, which may be valid or invalid
    * `config` - Keyword list of backend-specific configuration

  ## Returns
    * `{:cont, result}` - Continue with success, where result is a map (typically with `:message` and `:data`)
    * `{:halt, %Ecto.Changeset{}}` - Halt with validation errors to display on the form
    * `{:halt, error}` - Halt with a general error

  ## Examples

      def submit(data, changeset, config) do
        # Check if built-in validations passed
        if not changeset.valid? do
          {:halt, changeset}
        else
          # Custom validation or processing
          case process_submission(data, config) do
            {:ok, result} -> {:cont, %{message: "Success!", data: result}}
            {:error, reason} -> {:halt, %{message: "Failed: \#{reason}"}}
          end
        end
      end
  """
  @callback submit(form_data :: map(), changeset :: Ecto.Changeset.t(), config :: Keyword.t()) ::
              {:cont, map()} | {:halt, Ecto.Changeset.t()} | {:halt, map()}

  @doc """
  Validates the backend configuration.

  Returns `:ok` if configuration is valid, or `{:error, message}` if invalid.
  """
  @callback validate_config(config :: Keyword.t()) :: :ok | {:error, String.t()}
end
