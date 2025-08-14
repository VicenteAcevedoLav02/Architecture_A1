defmodule ArchitectureA1.Authors do
  alias Mongo

  def get_all_authors() do
    Mongo.find(ArchitectureA1.Mongo, "authors", %{})
    |> Enum.map(fn doc ->
      id = BSON.ObjectId.encode!(doc["_id"])
      Map.put(doc, :id, id)
      |> Map.delete("_id")
    end)
  end

  def create_author(attrs) do
    {:ok, result} = Mongo.insert_one(ArchitectureA1.Mongo, "authors", attrs)
    {:ok, result}
  rescue
    e -> {:error, e}
  end

  def update_author(id, attrs) do
    filter = %{"_id" => BSON.ObjectId.decode!(id)}
    update = %{"$set" => attrs}

    case Mongo.update_one(ArchitectureA1.Mongo, "authors", filter, update) do
      {:ok, %Mongo.UpdateResult{matched_count: 1}} ->
        {:ok, "Author updated successfully"}

      {:ok, %Mongo.UpdateResult{matched_count: 0}} ->
        {:error, "No author found with that ID"}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, e}
  end
end
