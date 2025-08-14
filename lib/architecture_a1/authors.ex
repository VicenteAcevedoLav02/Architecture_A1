defmodule ArchitectureA1.Authors do
  alias Mongo

  def get_all_authors() do
    Mongo.find(ArchitectureA1.Mongo, "authors", %{})
    |> Enum.to_list()
  end

  def create_author(attrs) do
    {:ok, result} = Mongo.insert_one(ArchitectureA1.Mongo, "authors", attrs)
    {:ok, result}
  rescue
    e -> {:error, e}
  end
end
