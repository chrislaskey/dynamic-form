defmodule DynamicForm.Backend do
  @moduledoc """
  Behaviour for form submission backends.

  Backend modules handle form submission after validation. Each backend implements
  how to process the validated form data.

  ## Example

      defmodule MyApp.EmailBackend do
        @behaviour DynamicForm.Backend

        @impl DynamicForm.Backend
        def submit(changeset, config) do
          recipient_email = Keyword.fetch!(config, :recipient_email)
          subject = Keyword.fetch!(config, :subject)

          if changeset.valid? do
            form_data = Ecto.Changeset.apply_changes(changeset)

            case send_email(recipient_email, subject, form_data) do
              {:ok, _result} ->
                {:ok, %{message: "Form submitted successfully via email"}}
              {:error, reason} ->
                {:error, %{message: "Failed to send email: \#{reason}"}}
            end
          else
            {:error, %{message: "Form validation failed", errors: changeset.errors}}
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
  """

  @doc """
  Submits the form data using the backend's implementation.

  Receives a validated changeset and backend-specific configuration.
  Returns `{:ok, result}` on success or `{:error, reason}` on failure.
  """
  @callback submit(changeset :: Ecto.Changeset.t(), config :: Keyword.t()) ::
              {:ok, map()} | {:error, map()}

  @doc """
  Validates the backend configuration.

  Returns `:ok` if configuration is valid, or `{:error, message}` if invalid.
  """
  @callback validate_config(config :: Keyword.t()) :: :ok | {:error, String.t()}
end
