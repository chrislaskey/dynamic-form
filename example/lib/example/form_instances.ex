defmodule Example.FormInstances do
  @moduledoc """
  Shared form instance configurations for testing DynamicForm renderers.

  This module provides reusable form instances that can be used across
  multiple test pages and examples.
  """

  alias DynamicForm.Instance

  @doc """
  Returns a contact form instance with various field types.

  This form includes:
  - Elements (heading, paragraph, divider)
  - String field (name)
  - Email field with format validation
  - Select field (subject)
  - Textarea field (message) with length validation
  - Decimal field (priority) with numeric range validation
  - Boolean field (subscribe)
  - Grouped contact preference fields
  """
  def contact_form do
    %Instance{
      id: "contact-form",
      name: "Contact Form",
      description: "Please fill out this form to get in touch with us.",
      items: [
        %Instance.Element{
          id: "contact-heading",
          type: "heading",
          content: "Contact Information",
          metadata: %{"level" => "h3"}
        },
        %Instance.Element{
          id: "contact-intro",
          type: "paragraph",
          content:
            "We'd love to hear from you! Fill out the form below and we'll get back to you as soon as possible.",
          metadata: %{"class" => "text-gray-600"}
        },
        %Instance.Field{
          id: "name",
          name: "name",
          type: "string",
          label: "Full Name",
          placeholder: "John Doe",
          help_text: "Enter your full name as it appears on official documents",
          required: true,
          validations: [
            %Instance.Validation{type: "min_length", value: 2}
          ]
        },
        %Instance.Field{
          id: "email",
          name: "email",
          type: "email",
          label: "Email Address",
          placeholder: "john@example.com",
          help_text: "We'll never share your email with anyone else",
          required: true,
          validations: [
            %Instance.Validation{type: "email_format"}
          ]
        },
        %Instance.Element{
          id: "contact-group",
          type: "group",
          content: "Contact Preferences",
          metadata: %{"layout" => "grid-2"},
          items: [
            %Instance.Field{
              id: "phone",
              name: "phone",
              type: "string",
              label: "Phone Number",
              placeholder: "(555) 123-4567",
              required: false
            },
            %Instance.Field{
              id: "preferred_contact",
              name: "preferred_contact",
              type: "select",
              label: "Preferred Contact Method",
              required: false,
              options: [
                {"Email", "email"},
                {"Phone", "phone"},
                {"Either", "either"}
              ]
            }
          ]
        },
        %Instance.Element{
          id: "divider-1",
          type: "divider"
        },
        %Instance.Element{
          id: "inquiry-heading",
          type: "heading",
          content: "Your Inquiry",
          metadata: %{"level" => "h3"}
        },
        %Instance.Field{
          id: "subject",
          name: "subject",
          type: "select",
          label: "Subject",
          help_text: "Choose the topic that best matches your inquiry",
          required: true,
          options: [
            {"General Inquiry", "general"},
            {"Technical Support", "support"},
            {"Sales", "sales"},
            {"Feedback", "feedback"}
          ]
        },
        %Instance.Field{
          id: "message",
          name: "message",
          type: "textarea",
          label: "Message",
          placeholder: "Tell us how we can help you...",
          help_text: "Please provide as much detail as possible",
          required: true,
          validations: [
            %Instance.Validation{type: "min_length", value: 10},
            %Instance.Validation{type: "max_length", value: 1000}
          ]
        },
        %Instance.Field{
          id: "priority",
          name: "priority",
          type: "decimal",
          label: "Priority (1-10)",
          placeholder: "5",
          help_text: "Rate the urgency of your request from 1 (low) to 10 (high)",
          required: false,
          validations: [
            %Instance.Validation{type: "numeric_range", min: 1, max: 10}
          ]
        },
        %Instance.Element{
          id: "divider-2",
          type: "divider"
        },
        %Instance.Field{
          id: "subscribe",
          name: "subscribe",
          type: "boolean",
          label: "Subscribe to newsletter",
          help_text: "Receive updates about new features and announcements",
          required: false
        },
        %Instance.Field{
          id: "newsletter_frequency",
          name: "newsletter_frequency",
          type: "select",
          label: "Newsletter Frequency",
          help_text: "How often would you like to receive our newsletter?",
          required: false,
          visible_when: %{
            field: "email",
            operator: "valid"
          },
          options: [
            {"Daily", "daily"},
            {"Weekly", "weekly"},
            {"Monthly", "monthly"}
          ]
        }
      ],
      backend: %Instance.Backend{
        module: Example.TestBackend,
        function: :submit,
        config: [],
        name: "Test Backend",
        description: "Logs form submissions for testing"
      },
      metadata: %{
        created_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Returns a payment form that demonstrates conditional field visibility.

  This form shows how fields can be conditionally displayed based on other field values:
  - Credit card fields only appear when payment method is "credit_card"
  - Bank account fields only appear when payment method is "bank_transfer"
  """
  def payment_form do
    %Instance{
      id: "payment-form",
      name: "Payment Form",
      description: "Complete your payment information below.",
      items: [
        %Instance.Element{
          id: "payment-heading",
          type: "heading",
          content: "Payment Method Selection",
          metadata: %{"level" => "h3"}
        },
        %Instance.Element{
          id: "payment-intro",
          type: "paragraph",
          content: "Select your preferred payment method and enter the required details below.",
          metadata: %{"class" => "text-gray-600"}
        },
        %Instance.Field{
          id: "payment_method",
          name: "payment_method",
          type: "select",
          label: "Payment Method",
          help_text: "Choose how you would like to pay",
          required: true,
          options: [
            {"Credit Card", "credit_card"},
            {"Bank Transfer", "bank_transfer"},
            {"PayPal", "paypal"}
          ]
        },
        %Instance.Element{
          id: "payment-divider-1",
          type: "divider"
        },
        # Credit card fields - only visible when payment_method is "credit_card"
        %Instance.Field{
          id: "card_number",
          name: "card_number",
          type: "string",
          label: "Card Number",
          placeholder: "1234 5678 9012 3456",
          help_text: "Enter your 16-digit card number",
          required: false,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "credit_card"
          },
          validations: [
            %Instance.Validation{type: "min_length", value: 13}
          ]
        },
        %Instance.Field{
          id: "card_expiry",
          name: "card_expiry",
          type: "string",
          label: "Expiry Date",
          placeholder: "MM/YY",
          help_text: "Card expiration date",
          required: false,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "credit_card"
          }
        },
        %Instance.Field{
          id: "card_cvv",
          name: "card_cvv",
          type: "string",
          label: "CVV",
          placeholder: "123",
          help_text: "3-digit security code on the back of your card",
          required: false,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "credit_card"
          },
          validations: [
            %Instance.Validation{type: "min_length", value: 3},
            %Instance.Validation{type: "max_length", value: 4}
          ]
        },
        # Bank transfer fields - only visible when payment_method is "bank_transfer"
        %Instance.Field{
          id: "account_number",
          name: "account_number",
          type: "string",
          label: "Account Number",
          placeholder: "1234567890",
          help_text: "Your bank account number",
          required: false,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "bank_transfer"
          }
        },
        %Instance.Field{
          id: "routing_number",
          name: "routing_number",
          type: "string",
          label: "Routing Number",
          placeholder: "021000021",
          help_text: "9-digit routing number for your bank",
          required: false,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "bank_transfer"
          },
          validations: [
            %Instance.Validation{type: "min_length", value: 9},
            %Instance.Validation{type: "max_length", value: 9}
          ]
        },
        # PayPal email - only visible when payment_method is "paypal"
        %Instance.Field{
          id: "paypal_email",
          name: "paypal_email",
          type: "email",
          label: "PayPal Email",
          placeholder: "you@example.com",
          help_text: "Email address associated with your PayPal account",
          required: false,
          visible_when: %{
            field: "payment_method",
            operator: "equals",
            value: "paypal"
          },
          validations: [
            %Instance.Validation{type: "email_format"}
          ]
        },
        %Instance.Element{
          id: "payment-divider-2",
          type: "divider"
        },
        # Amount field - always visible
        %Instance.Field{
          id: "amount",
          name: "amount",
          type: "decimal",
          label: "Amount",
          placeholder: "100.00",
          help_text: "Enter the payment amount in USD",
          required: true,
          validations: [
            %Instance.Validation{type: "numeric_range", min: 0.01, max: 10000}
          ]
        },
        # Save payment method checkbox - always visible
        %Instance.Field{
          id: "save_method",
          name: "save_method",
          type: "boolean",
          label: "Save this payment method for future use",
          help_text: "Securely store your payment details",
          required: false
        },
        %Instance.Element{
          id: "billing-heading",
          type: "heading",
          content: "Billing Information",
          metadata: %{"level" => "h3"}
        },
        %Instance.Element{
          id: "billing-address-group",
          type: "group",
          content: "Billing Address",
          metadata: %{"layout" => "grid-2"},
          items: [
            %Instance.Field{
              id: "billing_street",
              name: "billing_street",
              type: "string",
              label: "Street Address",
              placeholder: "123 Main St",
              required: true
            },
            %Instance.Field{
              id: "billing_city",
              name: "billing_city",
              type: "string",
              label: "City",
              placeholder: "San Francisco",
              required: true
            },
            %Instance.Field{
              id: "billing_state",
              name: "billing_state",
              type: "string",
              label: "State",
              placeholder: "CA",
              required: true
            },
            %Instance.Field{
              id: "billing_zip",
              name: "billing_zip",
              type: "string",
              label: "ZIP Code",
              placeholder: "94102",
              required: true,
              validations: [
                %Instance.Validation{type: "min_length", value: 5},
                %Instance.Validation{type: "max_length", value: 10}
              ]
            }
          ]
        }
      ],
      backend: %Instance.Backend{
        module: Example.TestBackend,
        function: :submit,
        config: [],
        name: "Test Backend",
        description: "Logs form submissions for testing"
      },
      metadata: %{
        created_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Returns a form demonstrating section elements.

  This form demonstrates:
  - Section elements with titles
  - Sections containing multiple fields and groups
  - Nested sections
  - Sections with custom classes
  - Conditional section visibility
  """
  def section_form do
    %Instance{
      id: "section-form",
      name: "User Profile Form",
      description: "Complete your profile information using sections.",
      items: [
        %Instance.Element{
          id: "personal-section",
          type: "section",
          content: "Personal Information",
          items: [
            %Instance.Element{
              id: "name-group",
              type: "group",
              content: "Full Name",
              metadata: %{"layout" => "grid-2"},
              items: [
                %Instance.Field{
                  id: "first_name",
                  name: "first_name",
                  type: "string",
                  label: "First Name",
                  placeholder: "John",
                  required: true
                },
                %Instance.Field{
                  id: "last_name",
                  name: "last_name",
                  type: "string",
                  label: "Last Name",
                  placeholder: "Doe",
                  required: true
                }
              ]
            },
            %Instance.Field{
              id: "email",
              name: "email",
              type: "email",
              label: "Email Address",
              placeholder: "john.doe@example.com",
              required: true,
              validations: [
                %Instance.Validation{type: "email_format"}
              ]
            }
          ]
        },
        %Instance.Element{
          id: "address-section",
          type: "section",
          content: "Address",
          metadata: %{"class" => "mt-6"},
          items: [
            %Instance.Field{
              id: "street",
              name: "street",
              type: "string",
              label: "Street Address",
              placeholder: "123 Main St",
              required: true
            },
            %Instance.Element{
              id: "city-state-group",
              type: "group",
              metadata: %{"layout" => "grid-3"},
              items: [
                %Instance.Field{
                  id: "city",
                  name: "city",
                  type: "string",
                  label: "City",
                  placeholder: "San Francisco",
                  required: true
                },
                %Instance.Field{
                  id: "state",
                  name: "state",
                  type: "string",
                  label: "State",
                  placeholder: "CA",
                  required: true
                },
                %Instance.Field{
                  id: "zip",
                  name: "zip",
                  type: "string",
                  label: "ZIP Code",
                  placeholder: "94102",
                  required: true
                }
              ]
            }
          ]
        },
        %Instance.Element{
          id: "preferences-section",
          type: "section",
          content: "Preferences",
          metadata: %{"class" => "mt-6"},
          items: [
            %Instance.Field{
              id: "newsletter",
              name: "newsletter",
              type: "boolean",
              label: "Subscribe to newsletter",
              help_text: "Receive weekly updates and news"
            },
            %Instance.Field{
              id: "newsletter_frequency",
              name: "newsletter_frequency",
              type: "select",
              label: "Newsletter Frequency",
              required: false,
              visible_when: %{
                field: "newsletter",
                operator: "equals",
                value: true
              },
              options: [
                {"Daily", "daily"},
                {"Weekly", "weekly"},
                {"Monthly", "monthly"}
              ]
            },
            %Instance.Field{
              id: "notification_method",
              name: "notification_method",
              type: "radio-group",
              label: "Notification Method",
              help_text: "Choose how you'd like to receive notifications",
              required: true,
              metadata: %{"style" => "vertical"},
              options: [
                {"Email Only", "email"},
                {"SMS Only", "sms"},
                {"Both Email and SMS", "both"},
                {"None", "none"}
              ]
            },
            %Instance.Field{
              id: "theme",
              name: "theme",
              type: "radio-group",
              label: "Theme Preference",
              help_text: "Select your preferred color theme",
              required: false,
              metadata: %{"style" => "horizontal"},
              options: [
                {"Light", "light"},
                {"Dark", "dark"},
                {"Auto", "auto"}
              ]
            }
          ]
        },
        %Instance.Element{
          id: "nested-section-parent",
          type: "section",
          content: "Additional Information",
          metadata: %{"class" => "mt-6"},
          items: [
            %Instance.Element{
              id: "bio-heading",
              type: "heading",
              content: "Biography",
              metadata: %{"level" => "h4"}
            },
            %Instance.Field{
              id: "bio",
              name: "bio",
              type: "textarea",
              label: "Tell us about yourself",
              placeholder: "Write a short bio...",
              required: false
            },
            %Instance.Element{
              id: "social-nested-section",
              type: "section",
              content: "Social Media Links",
              metadata: %{"class" => "mt-4"},
              items: [
                %Instance.Element{
                  id: "social-group",
                  type: "group",
                  metadata: %{"layout" => "grid-2"},
                  items: [
                    %Instance.Field{
                      id: "twitter",
                      name: "twitter",
                      type: "string",
                      label: "Twitter",
                      placeholder: "@username"
                    },
                    %Instance.Field{
                      id: "linkedin",
                      name: "linkedin",
                      type: "string",
                      label: "LinkedIn",
                      placeholder: "linkedin.com/in/username"
                    }
                  ]
                }
              ]
            }
          ]
        },
        %Instance.Element{
          id: "documents-section",
          type: "section",
          content: "Profile Documents",
          metadata: %{"class" => "mt-6"},
          items: [
            %Instance.Element{
              id: "documents-intro",
              type: "paragraph",
              content:
                "Upload any supporting documents for your profile (resume, certifications, etc.)",
              metadata: %{"class" => "text-gray-600 text-sm mb-4"}
            },
            %Instance.Field{
              id: "profile_documents",
              name: "profile_documents",
              type: "direct_upload",
              label: "Documents",
              help_text: "Upload up to 3 files (PDF, DOC, DOCX, or images - max 10MB each)",
              required: false,
              metadata: %{
                "max_entries" => 3,
                "max_file_size" => 10_000_000,
                "accept" => [".pdf", ".doc", ".docx", "image/*"],
                "presigner" => %{
                  "module" => "Example.MockUrlPresigner",
                  "function" => "sign"
                },
                "bucket" => "user-profiles",
                "object_name_prefix" => "profile-documents/"
              }
            }
          ]
        }
      ],
      backend: %Instance.Backend{
        module: Example.TestBackend,
        function: :submit,
        config: [],
        name: "Test Backend",
        description: "Logs form submissions for testing"
      },
      metadata: %{
        created_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Returns a comprehensive showcase form demonstrating all DynamicForm features.

  This form demonstrates:
  - All element types (heading, paragraph, divider, group, section)
  - All field types (string, email, textarea, decimal, boolean, select)
  - Groups with different layouts (grid-2, grid-3, horizontal)
  - Conditional visibility (equals and valid operators)
  - Nested groups
  - Field validations
  """
  def showcase_form do
    %{
      id: "showcase-form",
      name: "DynamicForm Feature Showcase",
      description: "A comprehensive example showcasing all DynamicForm capabilities.",
      items: [
        %{
          id: "intro-heading",
          type: "heading",
          content: "Welcome to DynamicForm",
          metadata: %{"level" => "h2"}
        },
        %{
          id: "intro-paragraph",
          type: "paragraph",
          content:
            "This form demonstrates all the features of the DynamicForm library including elements, groups, conditional visibility, and various field types.",
          metadata: %{"class" => "text-gray-600 text-lg"}
        },
        %{
          id: "divider-intro",
          type: "divider"
        },
        %{
          id: "personal-heading",
          type: "heading",
          content: "Personal Information",
          metadata: %{"level" => "h3"}
        },
        %{
          id: "name-group",
          type: "group",
          content: "Full Name",
          metadata: %{"layout" => "grid-2"},
          items: [
            %{
              id: "first_name",
              name: "first_name",
              type: "string",
              label: "First Name",
              placeholder: "John",
              required: true,
              validations: [
                %{type: "min_length", value: 2}
              ]
            },
            %{
              id: "last_name",
              name: "last_name",
              type: "string",
              label: "Last Name",
              placeholder: "Doe",
              required: true,
              validations: [
                %{type: "min_length", value: 2}
              ]
            }
          ]
        },
        %{
          id: "email",
          name: "email",
          type: "email",
          label: "Email Address",
          placeholder: "john.doe@example.com",
          required: true,
          validations: [
            %{type: "email_format"}
          ]
        },
        %{
          id: "email-prefs-group",
          type: "group",
          content: "Email Preferences",
          metadata: %{"layout" => "horizontal"},
          visible_when: %{
            field: "email",
            operator: "valid"
          },
          items: [
            %{
              id: "email_notifications",
              name: "email_notifications",
              type: "boolean",
              label: "Receive email notifications"
            },
            %{
              id: "email_frequency",
              name: "email_frequency",
              type: "select",
              label: "Frequency",
              options: [
                {"Daily", "daily"},
                {"Weekly", "weekly"},
                {"Monthly", "monthly"}
              ]
            }
          ]
        },
        %{
          id: "divider-1",
          type: "divider"
        },
        %{
          id: "address-heading",
          type: "heading",
          content: "Address",
          metadata: %{"level" => "h3"}
        },
        %{
          id: "address-group",
          type: "group",
          metadata: %{"layout" => "vertical"},
          items: [
            %{
              id: "street",
              name: "street",
              type: "string",
              label: "Street Address",
              placeholder: "123 Main St",
              required: true
            },
            %{
              id: "city-state-zip-group",
              type: "group",
              metadata: %{"layout" => "grid-3"},
              items: [
                %{
                  id: "city",
                  name: "city",
                  type: "string",
                  label: "City",
                  placeholder: "San Francisco",
                  required: true
                },
                %{
                  id: "state",
                  name: "state",
                  type: "string",
                  label: "State",
                  placeholder: "CA",
                  required: true,
                  validations: [
                    %{type: "max_length", value: 2}
                  ]
                },
                %{
                  id: "zip",
                  name: "zip",
                  type: "string",
                  label: "ZIP",
                  placeholder: "94102",
                  required: true,
                  validations: [
                    %{type: "min_length", value: 5},
                    %{type: "max_length", value: 10}
                  ]
                }
              ]
            }
          ]
        },
        %{
          id: "divider-2",
          type: "divider"
        },
        %{
          id: "feedback-heading",
          type: "heading",
          content: "Feedback",
          metadata: %{"level" => "h3"}
        },
        %{
          id: "category",
          name: "category",
          type: "select",
          label: "Feedback Category",
          required: true,
          options: [
            {"Bug Report", "bug"},
            {"Feature Request", "feature"},
            {"General Feedback", "general"}
          ]
        },
        %{
          id: "rating",
          name: "rating",
          type: "decimal",
          label: "Rating (1-10)",
          placeholder: "8",
          required: true,
          validations: [
            %{type: "numeric_range", min: 1, max: 10}
          ]
        },
        %{
          id: "comments",
          name: "comments",
          type: "textarea",
          label: "Comments",
          placeholder: "Tell us more...",
          required: true,
          validations: [
            %{type: "min_length", value: 10},
            %{type: "max_length", value: 500}
          ]
        },
        %{
          id: "thank-you",
          type: "paragraph",
          content: "Thank you for providing your feedback!",
          metadata: %{"class" => "text-green-600 font-semibold"},
          visible_when: %{
            field: "comments",
            operator: "valid"
          }
        }
      ],
      backend: %{
        module: Example.TestBackend,
        function: :submit,
        config: [],
        name: "Test Backend",
        description: "Logs form submissions for testing"
      },
      metadata: %{
        created_at: DateTime.utc_now()
      }
    }
  end
end
