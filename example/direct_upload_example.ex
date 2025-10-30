defmodule DynamicForm.Example.DirectUploadExample do
  @moduledoc """
  Example implementation of direct file upload using DynamicForm.

  This example shows how to create a form with file upload functionality
  that integrates with the existing DirectorWeb upload pattern.

  ## Prerequisites

  1. A presigner module that generates presigned URLs for cloud storage
  2. A cloud storage bucket configured for uploads
  3. Optional: A deletion callback for removing files from storage

  ## Example Form Instance

      defmodule MyApp.Forms.DocumentUpload do
        alias DynamicForm.Instance
        alias DynamicForm.Instance.{Field, Element, Backend}

        def build_form do
          %Instance{
            id: "document-upload-form",
            name: "Document Upload Form",
            description: "Upload required documents",
            items: [
              %Element{
                id: "heading-1",
                type: "heading",
                content: "Upload Your Documents",
                metadata: %{"level" => "h2"}
              },
              %Element{
                id: "instructions",
                type: "paragraph",
                content: "Please upload all required documents. Maximum 10MB per file."
              },
              %Field{
                id: "applicant_name",
                name: "applicant_name",
                type: "string",
                label: "Applicant Name",
                required: true
              },
              %Field{
                id: "documents",
                name: "documents",
                type: "direct_upload",
                label: "Supporting Documents",
                help_text: "Upload up to 3 files (PDF, DOC, DOCX, or images)",
                required: true,
                metadata: %{
                  "max_entries" => 3,
                  "max_file_size" => 10_000_000,
                  "accept" => [".pdf", ".doc", ".docx", "image/*"],
                  "presigner" => %{
                    "module" => "MyApp.Licensing.UrlPresigner",
                    "function" => "sign"
                  },
                  "bucket" => "my-application-uploads",
                  "object_name_prefix" => "license-applications/documents/"
                }
              }
            ],
            backend: %Backend{
              module: MyApp.Forms.DocumentUploadBackend,
              function: :submit,
              config: [
                notification_email: "admin@example.com"
              ]
            }
          }
        end
      end

  ## Presigner Implementation

  The presigner module should implement the following pattern:

      defmodule MyApp.Licensing.UrlPresigner do
        @moduledoc \"\"\"
        Generates presigned URLs for direct file uploads to Google Cloud Storage.
        \"\"\"

        def sign(filename, context) do
          bucket = context.bucket
          prefix = context.prefix || ""
          object_name = "\#{prefix}\#{filename}"

          # Use the existing CoreData.Clients.UrlPresigner pattern
          CoreData.Clients.UrlPresigner.sign(bucket, object_name)
        end
      end

  ## Backend Implementation

  The backend receives the uploaded file metadata:

      defmodule MyApp.Forms.DocumentUploadBackend do
        @behaviour DynamicForm.Backend

        @impl true
        def submit(data, changeset, config) do
          # data is a map with field values including the uploaded files
          # %{
          #   applicant_name: "John Doe",
          #   documents: [
          #     %{
          #       "filename" => "resume.pdf",
          #       "cloud_bucket" => "my-application-uploads",
          #       "cloud_path" => "license-applications/documents/resume.pdf",
          #       "cloud_provider" => "gcp",
          #       "uploaded_on" => "10/28/2025"
          #     }
          #   ]
          # }

          # Check if built-in validations passed
          if not changeset.valid? do
            {:halt, changeset}
          else
            # Process the submission
            case save_application(data, config) do
              {:ok, application} ->
                {:cont, %{message: "Application submitted successfully", application: application}}

              {:error, reason} ->
                {:halt, %{message: "Failed to submit application", reason: reason}}
            end
          end
        end

        @impl true
        def validate_config(_config) do
          :ok
        end

        defp save_application(data, _config) do
          # Your business logic here
          # Save to database, send notifications, etc.
          {:ok, data}
        end
      end

  ## Using in a LiveView

      defmodule MyAppWeb.DocumentUploadLive do
        use MyAppWeb, :live_view

        alias MyApp.Forms.DocumentUpload

        @impl true
        def mount(_params, _session, socket) do
          form_instance = DocumentUpload.build_form()

          socket =
            socket
            |> assign(:form_instance, form_instance)

          {:ok, socket}
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div class="max-w-2xl mx-auto p-6">
            <.live_component
              module={DynamicForm.RendererLive}
              id="document-upload-form"
              instance={@form_instance}
              send_messages={true}
            />
          </div>
          \"\"\"
        end

        @impl true
        def handle_info({:dynamic_form_success, _id, result}, socket) do
          {:noreply, put_flash(socket, :info, result.message)}
        end

        @impl true
        def handle_info({:dynamic_form_error, _id, error}, socket) do
          {:noreply, put_flash(socket, :error, error.message)}
        end

        # Handle upload state changes
        @impl true
        def handle_info(:uploads_not_ready, socket) do
          # Optionally disable submit button or show loading state
          {:noreply, socket}
        end

        @impl true
        def handle_info(:uploads_ready, socket) do
          # Re-enable submit button
          {:noreply, socket}
        end
      end

  ## File Deletion (Optional)

  To enable file deletion from cloud storage when users remove files from the upload component,
  you can configure a deletion callback in the field metadata:

      %Field{
        # ... other config ...
        metadata: %{
          # ... other metadata ...
          "deleter" => %{
            "module" => "MyApp.Licensing.FileDeleter",
            "function" => "delete"
          }
        }
      }

  The deleter module should implement:

      defmodule MyApp.Licensing.FileDeleter do
        def delete(cloud_path, context) do
          bucket = context.bucket
          CoreData.Clients.CloudStorage.delete(cloud_path, bucket: bucket)
        end
      end

  ## Integration with DirectorWeb Pattern

  This implementation is compatible with the existing DirectorWeb licensing upload pattern.
  You can migrate existing upload pages to use DynamicForm by:

  1. Convert your upload page configuration to a DynamicForm.Instance
  2. Replace the custom upload component with DynamicForm.RendererLive
  3. Use your existing presigner and cloud storage configuration

  Example migration from DirectorWeb.LicensingLive.NewMexico.Components.Upload:

      # Before (custom component)
      <.live_component
        module={DirectorWeb.LicensingLive.NewMexico.Components.Upload}
        id="documents-upload"
        title="Supporting Documents"
        application={@application}
        step_name={@step_name}
      />

      # After (DynamicForm)
      <.live_component
        module={DynamicForm.RendererLive}
        id="documents-upload"
        instance={build_upload_form(@application, @step_name)}
        send_messages={true}
      />

  The presigner callback remains the same:

      def sign(filename, context) do
        %{url_safe_object_name: object_name, bucket: bucket} =
          DirectorCore.Licensing.NewMexico.Files.step_file_object_data(
            filename,
            context.application,
            context.step_name
          )

        CoreData.Clients.UrlPresigner.sign(bucket, object_name)
      end
  """
end
