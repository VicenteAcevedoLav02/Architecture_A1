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

  def get_book_by_id(id) do
    case BSON.ObjectId.decode(id) do
      {:ok, obj_id} ->
        case Mongo.find_one(ArchitectureA1.Mongo, "books", %{"_id" => obj_id}) do
          nil -> nil
          doc -> Map.put(doc, :id, BSON.ObjectId.encode!(doc["_id"]))
        end

      :error ->
        nil
    end
  end

  def create_book(attrs) do
    {:ok, result} = Mongo.insert_one(ArchitectureA1.Mongo, "books", attrs)
    {:ok, result}
  rescue
    e -> {:error, e}
  end

  def update_book(id, attrs) do
    filter = %{"_id" => BSON.ObjectId.decode!(id)}
    update = %{"$set" => attrs}

    case Mongo.update_one(ArchitectureA1.Mongo, "books", filter, update) do
      {:ok, %Mongo.UpdateResult{matched_count: 1}} ->
        {:ok, "Book updated successfully"}

      {:ok, %Mongo.UpdateResult{matched_count: 0}} ->
        {:error, "No book found with that ID"}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, e}
  end

  def delete_book(id) do
    filter = %{"_id" => BSON.ObjectId.decode!(id)}

    case Mongo.delete_one(ArchitectureA1.Mongo, "books", filter) do
      {:ok, %Mongo.DeleteResult{deleted_count: 1}} ->
        {:ok, "Book deleted successfully"}

      {:ok, %Mongo.DeleteResult{deleted_count: 0}} ->
        {:error, "No book found with that ID"}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, e}
  end
end
