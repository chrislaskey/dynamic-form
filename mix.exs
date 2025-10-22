defmodule DynamicForm.MixProject do
  use Mix.Project

  def project do
    [
      app: :dynamic_form,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:ecto, "~> 3.10"}
    ]
  end
end
