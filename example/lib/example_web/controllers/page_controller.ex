defmodule ExampleWeb.PageController do
  use ExampleWeb, :controller

  def home(conn, _params) do
    # Create a test instance
    test_instance = DynamicForm.Instance.new("test-1", "Test Form",
      description: "A test form to verify library loading"
    )

    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home,
      layout: false,
      test_instance: test_instance
    )
  end
end
