defmodule DynamicForm.Instance do
  @moduledoc """
  Configuration struct that defines the complete form structure.

  This is a simple initial version to test the library setup.
  """

  @enforce_keys [:id, :name]
  defstruct [
    :id,
    :name,
    :description,
    :fourth,
    fields: [],
    metadata: %{}
  ]

  @doc """
  Creates a new form instance.
  """
  def new(id, name, opts \\ []) do
    %__MODULE__{
      id: id,
      name: name,
      description: Keyword.get(opts, :description),
      fields: Keyword.get(opts, :fields, []),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end
end
