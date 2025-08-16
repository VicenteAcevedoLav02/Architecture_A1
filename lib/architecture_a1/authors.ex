defmodule ArchitectureA1.Authors do
  alias Mongo
  alias ArchitectureA1.Books
  alias ArchitectureA1.Reviews

  def get_all_authors() do
    Mongo.find(ArchitectureA1.Mongo, "authors", %{})
    |> Enum.map(fn doc ->
      id = BSON.ObjectId.encode!(doc["_id"])
      Map.put(doc, :id, id)
      |> Map.delete("_id")
    end)
  end

  def get_author_by_id(id) do
    case BSON.ObjectId.decode(id) do
      {:ok, obj_id} ->
        case Mongo.find_one(ArchitectureA1.Mongo, "authors", %{"_id" => obj_id}) do
          nil -> nil
          doc -> Map.put(doc, :id, BSON.ObjectId.encode!(doc["_id"]))
        end

      :error ->
        nil
    end
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

  def delete_author(id) do
    filter = %{"_id" => BSON.ObjectId.decode!(id)}

    case Mongo.delete_one(ArchitectureA1.Mongo, "authors", filter) do
      {:ok, %Mongo.DeleteResult{deleted_count: 1}} ->
        {:ok, "Author deleted successfully"}

      {:ok, %Mongo.DeleteResult{deleted_count: 0}} ->
        {:error, "No author found with that ID"}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, e}
  end

  def list_authors_stats do
    authors = get_all_authors()

    Enum.map(authors, fn author ->
      books =
        Books.get_all_books()
        |> Enum.filter(&(&1["author_id"] == author.id))

        total_sales =
          books
          |> Enum.map(&String.to_integer(&1["number_of_sales"]))
          |> Enum.sum()

        all_scores =
          books
          |> Enum.flat_map(fn book ->
            Reviews.list_by_book(book.id)
            |> Enum.map(&(&1["score"] || &1[:score]))
          end)

        avg_score =
          case all_scores do
            [] -> nil
            scores -> Enum.sum(scores) / length(scores)
          end

        %{
          id: author.id,
          name: author["name"] || author[:name],
          books_count: length(books),
          avg_score: avg_score,
          total_sales: total_sales
        }
    end)
  end

end
