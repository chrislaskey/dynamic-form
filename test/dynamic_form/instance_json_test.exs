defmodule DynamicForm.InstanceJsonTest do
  use ExUnit.Case, async: true

  alias DynamicForm.Instance

  describe "JSON encoding and decoding" do
    setup do
      # Create a sample instance
      instance = %Instance{
        id: "test-form",
        name: "Test Form",
        description: "A test form",
        items: [
          %Instance.Element{
            id: "heading-1",
            type: "heading",
            content: "Personal Info",
            metadata: %{"level" => "h2"}
          },
          %Instance.Field{
            id: "name",
            name: "name",
            type: "string",
            label: "Full Name",
            placeholder: "John Doe",
            required: true,
            validations: [
              %Instance.Validation{type: "min_length", value: 2}
            ]
          },
          %Instance.Field{
            id: "email",
            name: "email",
            type: "email",
            label: "Email",
            required: true,
            validations: [
              %Instance.Validation{type: "email_format"}
            ]
          },
          %Instance.Field{
            id: "age",
            name: "age",
            type: "decimal",
            label: "Age",
            validations: [
              %Instance.Validation{type: "numeric_range", min: 18, max: 120}
            ]
          },
          %Instance.Field{
            id: "subscribe",
            name: "subscribe",
            type: "boolean",
            label: "Subscribe to newsletter"
          },
          %Instance.Field{
            id: "country",
            name: "country",
            type: "select",
            label: "Country",
            options: [
              {"United States", "us"},
              {"Canada", "ca"},
              {"Mexico", "mx"}
            ]
          },
          %Instance.Element{
            id: "group-1",
            type: "group",
            content: "Address",
            metadata: %{"layout" => "grid-2"},
            items: [
              %Instance.Field{
                id: "street",
                name: "street",
                type: "string",
                label: "Street"
              },
              %Instance.Field{
                id: "city",
                name: "city",
                type: "string",
                label: "City"
              }
            ]
          }
        ],
        backend: %Instance.Backend{
          module: Example.TestBackend,
          function: :submit,
          config: [recipient: "admin@example.com"],
          name: "Test Backend",
          description: "A test backend"
        },
        metadata: %{"version" => "1.0"},
        inserted_at: ~U[2024-01-01 12:00:00Z],
        updated_at: ~U[2024-01-15 14:30:00Z]
      }

      %{instance: instance}
    end

    test "encodes instance to JSON", %{instance: instance} do
      assert {:ok, json} = Jason.encode(instance)
      assert is_binary(json)
      assert json =~ "test-form"
      assert json =~ "Test Form"
    end

    test "decodes JSON back to instance", %{instance: instance} do
      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      assert decoded.id == instance.id
      assert decoded.name == instance.name
      assert decoded.description == instance.description
      assert length(decoded.items) == length(instance.items)
    end

    test "decodes map to instance", %{instance: instance} do
      map = Jason.encode!(instance) |> Jason.decode!()
      decoded = Instance.decode!(map)

      assert decoded.id == instance.id
      assert decoded.name == instance.name
      assert decoded.description == instance.description
    end

    test "preserves field properties", %{instance: instance} do
      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      name_field = Enum.find(decoded.items, &(&1.id == "name"))
      assert name_field.name == "name"
      assert name_field.type == "string"
      assert name_field.label == "Full Name"
      assert name_field.placeholder == "John Doe"
      assert name_field.required == true
      assert length(name_field.validations) == 1
    end

    test "preserves element properties", %{instance: instance} do
      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      heading = Enum.find(decoded.items, &(&1.id == "heading-1"))
      assert heading.type == "heading"
      assert heading.content == "Personal Info"
      assert heading.metadata["level"] == "h2"
    end

    test "preserves nested items in groups", %{instance: instance} do
      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      group = Enum.find(decoded.items, &(&1.id == "group-1"))
      assert group.type == "group"
      assert group.content == "Address"
      assert length(group.items) == 2

      street_field = Enum.find(group.items, &(&1.id == "street"))
      assert street_field.name == "street"
    end

    test "preserves backend configuration", %{instance: instance} do
      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      assert decoded.backend.module == Example.TestBackend
      assert decoded.backend.function == :submit
      assert decoded.backend.config == [recipient: "admin@example.com"]
      assert decoded.backend.name == "Test Backend"
    end

    test "preserves select field options", %{instance: instance} do
      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      country_field = Enum.find(decoded.items, &(&1.id == "country"))

      assert country_field.options == [
               {"United States", "us"},
               {"Canada", "ca"},
               {"Mexico", "mx"}
             ]
    end

    test "preserves validation rules", %{instance: instance} do
      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      age_field = Enum.find(decoded.items, &(&1.id == "age"))
      validation = List.first(age_field.validations)
      assert validation.type == "numeric_range"
      assert validation.min == 18
      assert validation.max == 120
    end

    test "preserves DateTime fields", %{instance: instance} do
      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      assert decoded.inserted_at == instance.inserted_at
      assert decoded.updated_at == instance.updated_at
    end

    test "handles nil DateTime fields" do
      instance = %Instance{
        id: "simple",
        name: "Simple",
        items: [],
        inserted_at: nil,
        updated_at: nil
      }

      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      assert decoded.inserted_at == nil
      assert decoded.updated_at == nil
    end

    test "round trip maintains data integrity", %{instance: instance} do
      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)
      json2 = Jason.encode!(decoded)
      decoded2 = Instance.decode!(json2)

      assert decoded.id == decoded2.id
      assert decoded.name == decoded2.name
      assert length(decoded.items) == length(decoded2.items)
    end

    test "preserves visible_when conditions" do
      instance = %Instance{
        id: "conditional-form",
        name: "Conditional Form",
        items: [
          %Instance.Field{
            id: "email",
            name: "email",
            type: "email",
            label: "Email"
          },
          %Instance.Field{
            id: "email_prefs",
            name: "email_prefs",
            type: "select",
            label: "Email Preferences",
            visible_when: %{
              field: "email",
              operator: "valid"
            },
            options: [{"Daily", "daily"}, {"Weekly", "weekly"}]
          },
          %Instance.Field{
            id: "payment_method",
            name: "payment_method",
            type: "select",
            label: "Payment Method",
            options: [{"Card", "card"}, {"Cash", "cash"}]
          },
          %Instance.Field{
            id: "card_number",
            name: "card_number",
            type: "string",
            label: "Card Number",
            visible_when: %{
              field: "payment_method",
              operator: "equals",
              value: "card"
            }
          }
        ]
      }

      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      email_prefs = Enum.find(decoded.items, &(&1.id == "email_prefs"))

      assert email_prefs.visible_when == %{
               "field" => "email",
               "operator" => "valid",
               "value" => nil
             }

      card_number = Enum.find(decoded.items, &(&1.id == "card_number"))

      assert card_number.visible_when == %{
               "field" => "payment_method",
               "operator" => "equals",
               "value" => "card"
             }
    end
  end

  describe "backend decoding" do
    test "decodes backend with module, function, and config" do
      instance = %Instance{
        id: "backend-form",
        name: "Backend Form",
        items: [],
        backend: %Instance.Backend{
          module: Example.TestBackend,
          function: :submit,
          config: [recipient: "admin@example.com", cc: "support@example.com"],
          name: "Email Backend",
          description: "Sends emails"
        }
      }

      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      assert decoded.backend.module == Example.TestBackend
      assert decoded.backend.function == :submit
      assert decoded.backend.name == "Email Backend"
      assert decoded.backend.description == "Sends emails"

      # Config is decoded as keyword list
      assert Keyword.get(decoded.backend.config, :recipient) == "admin@example.com"
      assert Keyword.get(decoded.backend.config, :cc) == "support@example.com"
    end

    test "decodes backend from plain map" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => [],
        "backend" => %{
          "module" => "Elixir.Example.TestBackend",
          "function" => "submit",
          "config" => [
            %{"key" => "recipient", "value" => "test@example.com"}
          ],
          "name" => "Test Backend"
        }
      }

      decoded = Instance.decode!(map)

      assert decoded.backend.module == Example.TestBackend
      assert decoded.backend.function == :submit
      assert decoded.backend.name == "Test Backend"
      assert Keyword.get(decoded.backend.config, :recipient) == "test@example.com"
    end

    test "handles backend with empty config" do
      instance = %Instance{
        id: "test",
        name: "Test",
        items: [],
        backend: %Instance.Backend{
          module: Example.TestBackend,
          function: :submit,
          config: []
        }
      }

      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      assert decoded.backend.config == []
    end
  end

  describe "metadata decoding" do
    test "preserves instance metadata" do
      metadata = %{
        "version" => "1.0",
        "author" => "John Doe",
        "tags" => ["contact", "public"],
        "settings" => %{"theme" => "dark", "notifications" => true}
      }

      instance = %Instance{
        id: "metadata-form",
        name: "Metadata Form",
        items: [],
        metadata: metadata
      }

      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      assert decoded.metadata["version"] == "1.0"
      assert decoded.metadata["author"] == "John Doe"
      assert decoded.metadata["tags"] == ["contact", "public"]
      assert decoded.metadata["settings"]["theme"] == "dark"
      assert decoded.metadata["settings"]["notifications"] == true
    end

    test "preserves field metadata" do
      instance = %Instance{
        id: "test",
        name: "Test",
        items: [
          %Instance.Field{
            id: "phone",
            name: "phone",
            type: "string",
            metadata: %{
              "pattern" => "^\\d{3}-\\d{3}-\\d{4}$",
              "inputmode" => "tel",
              "autocomplete" => "tel"
            }
          }
        ]
      }

      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      field = List.first(decoded.items)
      assert field.metadata["pattern"] == "^\\d{3}-\\d{3}-\\d{4}$"
      assert field.metadata["inputmode"] == "tel"
      assert field.metadata["autocomplete"] == "tel"
    end

    test "preserves element metadata" do
      instance = %Instance{
        id: "test",
        name: "Test",
        items: [
          %Instance.Element{
            id: "heading",
            type: "heading",
            content: "Title",
            metadata: %{
              "level" => "h1",
              "class" => "text-3xl font-bold",
              "data-testid" => "page-title"
            }
          }
        ]
      }

      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      element = List.first(decoded.items)
      assert element.metadata["level"] == "h1"
      assert element.metadata["class"] == "text-3xl font-bold"
      assert element.metadata["data-testid"] == "page-title"
    end

    test "handles nil metadata" do
      instance = %Instance{
        id: "test",
        name: "Test",
        items: [
          %Instance.Field{
            id: "name",
            name: "name",
            type: "string",
            metadata: nil
          }
        ]
      }

      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      field = List.first(decoded.items)
      assert field.metadata == nil
    end
  end

  describe "plain map decoding" do
    test "decodes plain map without __type__ fields" do
      map = %{
        "id" => "plain-form",
        "name" => "Plain Form",
        "description" => "A form from a plain map",
        "items" => [
          %{
            "id" => "email",
            "name" => "email",
            "type" => "email",
            "label" => "Email",
            "required" => true
          }
        ]
      }

      decoded = Instance.decode!(map)

      assert decoded.id == "plain-form"
      assert decoded.name == "Plain Form"
      assert decoded.description == "A form from a plain map"
      assert length(decoded.items) == 1

      field = List.first(decoded.items)
      assert field.id == "email"
      assert field.name == "email"
      assert field.type == "email"
      assert field.required == true
    end

    test "decodes nested groups from plain maps" do
      map = %{
        "id" => "nested-form",
        "name" => "Nested Form",
        "items" => [
          %{
            "id" => "address-group",
            "type" => "group",
            "content" => "Address",
            "items" => [
              %{
                "id" => "street",
                "name" => "street",
                "type" => "string",
                "label" => "Street"
              },
              %{
                "id" => "city",
                "name" => "city",
                "type" => "string",
                "label" => "City"
              }
            ]
          }
        ]
      }

      decoded = Instance.decode!(map)

      group = List.first(decoded.items)
      assert group.type == "group"
      assert group.content == "Address"
      assert length(group.items) == 2

      street = List.first(group.items)
      assert street.name == "street"
    end

    test "decodes complex nested structure from plain map" do
      map = %{
        "id" => "complex-form",
        "name" => "Complex Form",
        "items" => [
          %{
            "id" => "section-1",
            "type" => "section",
            "content" => "Personal Info",
            "items" => [
              %{
                "id" => "name-group",
                "type" => "group",
                "metadata" => %{"layout" => "grid-2"},
                "items" => [
                  %{
                    "id" => "first_name",
                    "name" => "first_name",
                    "type" => "string",
                    "label" => "First Name",
                    "required" => true
                  },
                  %{
                    "id" => "last_name",
                    "name" => "last_name",
                    "type" => "string",
                    "label" => "Last Name",
                    "required" => true
                  }
                ]
              }
            ]
          }
        ]
      }

      decoded = Instance.decode!(map)

      section = List.first(decoded.items)
      assert section.type == "section"
      assert section.content == "Personal Info"

      group = List.first(section.items)
      assert group.type == "group"
      assert group.metadata["layout"] == "grid-2"

      first_name = List.first(group.items)
      assert first_name.name == "first_name"
      assert first_name.required == true
    end

    test "decodes with mixed __type__ and inferred types" do
      map = %{
        "id" => "mixed-form",
        "name" => "Mixed Form",
        "items" => [
          # Element with __type__
          %{
            "__type__" => "Element",
            "id" => "heading",
            "type" => "heading",
            "content" => "Title"
          },
          # Field without __type__ (inferred by name field)
          %{
            "id" => "email",
            "name" => "email",
            "type" => "email",
            "label" => "Email"
          },
          # Element without __type__ (inferred by lack of name field)
          %{
            "id" => "divider",
            "type" => "divider"
          }
        ]
      }

      decoded = Instance.decode!(map)

      assert length(decoded.items) == 3

      heading = Enum.at(decoded.items, 0)
      assert heading.__struct__ == Instance.Element
      assert heading.type == "heading"

      email = Enum.at(decoded.items, 1)
      assert email.__struct__ == Instance.Field
      assert email.name == "email"

      divider = Enum.at(decoded.items, 2)
      assert divider.__struct__ == Instance.Element
      assert divider.type == "divider"
    end
  end

  describe "decoder error handling" do
    test "raises error for missing required fields" do
      assert_raise KeyError, fn ->
        Instance.decode!(%{})
      end
    end

    test "raises error for non-existent module" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => [],
        "backend" => %{
          "module" => "NonExistent.Module",
          "function" => "submit",
          "config" => []
        }
      }

      assert_raise ArgumentError, ~r/Module.*is not loaded/, fn ->
        Instance.decode!(map)
      end
    end

    test "handles empty items list" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => []
      }

      decoded = Instance.decode!(map)
      assert decoded.items == []
    end

    test "handles nil backend" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => []
      }

      decoded = Instance.decode!(map)
      assert decoded.backend == nil
    end

    test "handles missing optional fields" do
      map = %{
        "id" => "minimal",
        "name" => "Minimal Form",
        "items" => []
      }

      decoded = Instance.decode!(map)

      assert decoded.id == "minimal"
      assert decoded.name == "Minimal Form"
      assert decoded.description == nil
      assert decoded.backend == nil
      assert decoded.metadata == nil
      assert decoded.inserted_at == nil
      assert decoded.updated_at == nil
    end
  end

  describe "string keys vs atom keys" do
    test "visible_when with atom keys" do
      instance = %Instance{
        id: "test",
        name: "Test",
        items: [
          %Instance.Field{
            id: "payment_method",
            name: "payment_method",
            type: "select",
            label: "Payment",
            options: [{"Card", "card"}]
          },
          %Instance.Field{
            id: "card_number",
            name: "card_number",
            type: "string",
            label: "Card Number",
            visible_when: %{
              field: "payment_method",
              operator: "equals",
              value: "card"
            }
          }
        ]
      }

      json = Jason.encode!(instance)
      decoded = Instance.decode!(json)

      card_field = Enum.at(decoded.items, 1)

      # After JSON round-trip, keys become strings
      assert card_field.visible_when == %{
               "field" => "payment_method",
               "operator" => "equals",
               "value" => "card"
             }
    end

    test "visible_when with string keys from plain map" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => [
          %{
            "id" => "email",
            "name" => "email",
            "type" => "email",
            "label" => "Email"
          },
          %{
            "id" => "prefs",
            "name" => "prefs",
            "type" => "select",
            "label" => "Preferences",
            "visible_when" => %{
              "field" => "email",
              "operator" => "valid"
            }
          }
        ]
      }

      decoded = Instance.decode!(map)

      prefs_field = Enum.at(decoded.items, 1)

      assert prefs_field.visible_when == %{
               "field" => "email",
               "operator" => "valid",
               "value" => nil
             }
    end

    test "metadata with string keys preserved" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => [
          %{
            "id" => "phone",
            "name" => "phone",
            "type" => "string",
            "metadata" => %{
              "pattern" => "^\\d{10}$",
              "maxlength" => "10",
              "custom_attr" => "value"
            }
          }
        ],
        "metadata" => %{
          "app_version" => "2.0",
          "form_category" => "contact"
        }
      }

      decoded = Instance.decode!(map)

      # Field metadata preserved with string keys
      field = List.first(decoded.items)
      assert field.metadata["pattern"] == "^\\d{10}$"
      assert field.metadata["maxlength"] == "10"
      assert field.metadata["custom_attr"] == "value"

      # Instance metadata preserved with string keys
      assert decoded.metadata["app_version"] == "2.0"
      assert decoded.metadata["form_category"] == "contact"
    end

    test "options as arrays of strings become tuples" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => [
          %{
            "id" => "country",
            "name" => "country",
            "type" => "select",
            "label" => "Country",
            "options" => [
              ["United States", "us"],
              ["Canada", "ca"],
              ["Mexico", "mx"]
            ]
          }
        ]
      }

      decoded = Instance.decode!(map)

      field = List.first(decoded.items)

      # Arrays become tuples
      assert field.options == [
               {"United States", "us"},
               {"Canada", "ca"},
               {"Mexico", "mx"}
             ]
    end

    test "options as plain strings remain strings" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => [
          %{
            "id" => "size",
            "name" => "size",
            "type" => "select",
            "label" => "Size",
            "options" => ["Small", "Medium", "Large"]
          }
        ]
      }

      decoded = Instance.decode!(map)

      field = List.first(decoded.items)
      assert field.options == ["Small", "Medium", "Large"]
    end

    test "validations with string keys" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => [
          %{
            "id" => "username",
            "name" => "username",
            "type" => "string",
            "label" => "Username",
            "validations" => [
              %{
                "type" => "min_length",
                "value" => 3,
                "message" => "Too short"
              },
              %{
                "type" => "max_length",
                "value" => 20,
                "message" => "Too long"
              }
            ]
          }
        ]
      }

      decoded = Instance.decode!(map)

      field = List.first(decoded.items)
      assert length(field.validations) == 2

      min_validation = Enum.at(field.validations, 0)
      assert min_validation.type == "min_length"
      assert min_validation.value == 3
      assert min_validation.message == "Too short"

      max_validation = Enum.at(field.validations, 1)
      assert max_validation.type == "max_length"
      assert max_validation.value == 20
      assert max_validation.message == "Too long"
    end

    test "backend config with string keys becomes keyword list" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => [],
        "backend" => %{
          "module" => "Elixir.Example.TestBackend",
          "function" => "submit",
          "config" => [
            %{"key" => "recipient", "value" => "admin@example.com"},
            %{"key" => "subject", "value" => "New Form Submission"},
            %{"key" => "template", "value" => "default"}
          ]
        }
      }

      decoded = Instance.decode!(map)

      # Config becomes keyword list with atom keys
      assert decoded.backend.config[:recipient] == "admin@example.com"
      assert decoded.backend.config[:subject] == "New Form Submission"
      assert decoded.backend.config[:template] == "default"

      # Verify it's actually a keyword list
      assert Keyword.keyword?(decoded.backend.config)
    end

    test "nested metadata with mixed string keys" do
      map = %{
        "id" => "test",
        "name" => "Test",
        "items" => [],
        "metadata" => %{
          "author" => "John Doe",
          "settings" => %{
            "theme" => "dark",
            "features" => %{
              "notifications" => true,
              "analytics" => false
            }
          },
          "tags" => ["important", "draft"]
        }
      }

      decoded = Instance.decode!(map)

      # All string keys preserved throughout nested structure
      assert decoded.metadata["author"] == "John Doe"
      assert decoded.metadata["settings"]["theme"] == "dark"
      assert decoded.metadata["settings"]["features"]["notifications"] == true
      assert decoded.metadata["settings"]["features"]["analytics"] == false
      assert decoded.metadata["tags"] == ["important", "draft"]
    end
  end

  describe "complex real-world scenarios" do
    test "decodes complete form with all features from plain map" do
      map = %{
        "id" => "complete-form",
        "name" => "Complete Registration Form",
        "description" => "User registration with all features",
        "items" => [
          %{
            "id" => "intro-heading",
            "type" => "heading",
            "content" => "Create Your Account",
            "metadata" => %{"level" => "h2"}
          },
          %{
            "id" => "email",
            "name" => "email",
            "type" => "email",
            "label" => "Email Address",
            "placeholder" => "you@example.com",
            "required" => true,
            "validations" => [
              %{"type" => "email_format", "message" => "Invalid email"}
            ]
          },
          %{
            "id" => "password",
            "name" => "password",
            "type" => "string",
            "label" => "Password",
            "required" => true,
            "validations" => [
              %{"type" => "min_length", "value" => 8}
            ]
          },
          %{
            "id" => "newsletter",
            "name" => "newsletter",
            "type" => "boolean",
            "label" => "Subscribe to newsletter"
          },
          %{
            "id" => "newsletter_frequency",
            "name" => "newsletter_frequency",
            "type" => "select",
            "label" => "Frequency",
            "visible_when" => %{
              "field" => "newsletter",
              "operator" => "equals",
              "value" => true
            },
            "options" => [
              ["Daily", "daily"],
              ["Weekly", "weekly"]
            ]
          }
        ],
        "backend" => %{
          "module" => "Elixir.Example.TestBackend",
          "function" => "submit",
          "config" => [
            %{"key" => "send_confirmation", "value" => true}
          ],
          "name" => "Registration Backend"
        },
        "metadata" => %{
          "version" => "2.0",
          "created_by" => "admin"
        }
      }

      decoded = Instance.decode!(map)

      # Verify top-level
      assert decoded.id == "complete-form"
      assert decoded.name == "Complete Registration Form"
      assert decoded.description == "User registration with all features"

      # Verify items
      assert length(decoded.items) == 5

      # Verify heading
      heading = Enum.at(decoded.items, 0)
      assert heading.__struct__ == Instance.Element
      assert heading.content == "Create Your Account"
      assert heading.metadata["level"] == "h2"

      # Verify email field with validation
      email = Enum.at(decoded.items, 1)
      assert email.__struct__ == Instance.Field
      assert email.required == true
      assert length(email.validations) == 1
      assert List.first(email.validations).type == "email_format"

      # Verify conditional field
      newsletter_freq = Enum.at(decoded.items, 4)
      assert newsletter_freq.visible_when["field"] == "newsletter"
      assert newsletter_freq.visible_when["operator"] == "equals"
      assert newsletter_freq.visible_when["value"] == true

      # Verify options
      assert newsletter_freq.options == [{"Daily", "daily"}, {"Weekly", "weekly"}]

      # Verify backend
      assert decoded.backend.module == Example.TestBackend
      assert decoded.backend.function == :submit
      assert Keyword.get(decoded.backend.config, :send_confirmation) == true

      # Verify metadata
      assert decoded.metadata["version"] == "2.0"
      assert decoded.metadata["created_by"] == "admin"
    end
  end
end
