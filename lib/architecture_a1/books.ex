defmodule ArchitectureA1.Books do
  alias Mongo

  def get_all_books() do
    Mongo.find(ArchitectureA1.Mongo, "books", %{})
    |> Enum.map(fn doc ->
      id = BSON.ObjectId.encode!(doc["_id"])
      Map.put(doc, :id, id)
      |> Map.delete("_id")
    end)
  end

  def create_book(attrs) do
    {:ok, result} = Mongo.insert_one(ArchitectureA1.Mongo, "books", attrs)
    {:ok, result}
  rescue
    e -> {:error, e}
  end
end
