defmodule ArchitectureA1.Authors do
  alias Mongo
  alias ArchitectureA1.Books
  alias ArchitectureA1.Reviews
  alias ArchitectureA1.Cache

  @all_authors_cache_key "authors:all"
  @stats_cache_key "authors:stats"

  defp author_cache_key(id), do: "author:#{id}"

  def invalidate_stats_cache() do
    Cache.delete(@stats_cache_key)
  end

  def get_all_authors() do
    # Checking cache first
    case Cache.get(@all_authors_cache_key) do
      # CACHE HIT
      authors when is_list(authors) ->
        IO.puts("Got in a CACHE HIT")
        authors

      # CACHE MISS:
      nil ->
        IO.puts("Got in a CACHE MISS")
        authors_from_db =
          Mongo.find(ArchitectureA1.Mongo, "authors", %{})
          |> Enum.map(fn doc ->
            id = BSON.ObjectId.encode!(doc["_id"])
            Map.put(doc, :id, id)
            |> Map.delete("_id")
          end)

        #dbg(authors_from_db)

        # Store in cache with a TTL (Time To Live)
        Cache.put(@all_authors_cache_key, authors_from_db, ttl: :timer.minutes(10))

        # Return of data
        authors_from_db
    end
  end

  def get_author_by_id(id) do
    cache_key = author_cache_key(id)

    case Cache.get(cache_key) do
      # CACHE HIT
      author when is_map(author) ->
        author

      # CACHE MISS
      nil ->
        case BSON.ObjectId.decode(id) do
          {:ok, obj_id} ->
            case Mongo.find_one(ArchitectureA1.Mongo, "authors", %{"_id" => obj_id}) do
              nil -> nil
              doc ->
                author = Map.put(doc, :id, BSON.ObjectId.encode!(doc["_id"]))
                # Store individual author on cache
                Cache.put(cache_key, author, ttl: :timer.minutes(10))
                author
            end

          :error ->
            nil
        end
    end
  end

  def create_author(attrs) do
    case Mongo.insert_one(ArchitectureA1.Mongo, "authors", attrs) do
      {:ok, result} ->
        # Invalidating affected cache
        Cache.delete(@all_authors_cache_key)
        Cache.delete(@stats_cache_key)
        ArchitectureA1.Reviews.invalidate_top_rated_cache()
        {:ok, result}

      {:error, e} ->
        {:error, e}
    end
  end

  def update_author(id, attrs) do
    filter = %{"_id" => BSON.ObjectId.decode!(id)}
    update = %{"$set" => attrs}

    case Mongo.update_one(ArchitectureA1.Mongo, "authors", filter, update) do
      {:ok, %Mongo.UpdateResult{matched_count: 1}} ->
        # Invalidating affected cache
        Cache.delete(@all_authors_cache_key)
        Cache.delete(@stats_cache_key)
        Cache.delete(author_cache_key(id)) # Individual author cache key
        ArchitectureA1.Reviews.invalidate_top_rated_cache()
        {:ok, "Author updated successfully"}

      {:ok, %Mongo.UpdateResult{matched_count: 0}} ->
        {:error, "No author found with that ID"}

      {:error, reason} ->
        {:error, reason}

      other ->
        other
    end
  end

  def delete_author(id) do
    books = ArchitectureA1.Books.get_all_books()
    author_books = Enum.filter(books, fn book -> book["author_id"] == id end)

    Enum.each(author_books, fn book ->
      result = ArchitectureA1.Books.delete_book(book[:id])
    end)

    filter = %{"_id" => BSON.ObjectId.decode!(id)}

    case Mongo.delete_one(ArchitectureA1.Mongo, "authors", filter) do
      {:ok, %Mongo.DeleteResult{deleted_count: 1}} ->
        # Invalidating affected cache
        Cache.delete(@all_authors_cache_key)
        Cache.delete(@stats_cache_key)
        Cache.delete(author_cache_key(id)) # Individual author cache key
        ArchitectureA1.Reviews.invalidate_top_rated_cache()
        {:ok, "Author deleted successfully"}

      {:ok, %Mongo.DeleteResult{deleted_count: 0}} ->
        {:error, "No author found with that ID"}

      {:error, reason} ->
        {:error, reason}

      other ->
        other
    end
  end

  def list_authors_stats do
    case Cache.get(@stats_cache_key) do
      # CACHE HIT
      stats when is_list(stats) ->
        IO.puts("Got in a CACHE HIT")
        stats

      # CACHE MISS
      nil ->
        IO.puts("Got in a CACHE MISS")
        stats_from_db =
          get_all_authors()
          |> Enum.map(fn author ->
            books =
              Books.get_all_books()
              |> Enum.filter(&(&1["author_id"] == author.id))

            total_sales =
              books
              |> Enum.map(fn b ->
                case b["number_of_sales"] do
                  n when is_integer(n) -> n
                  n when is_binary(n) -> String.to_integer(n)
                  _ -> 0
                end
              end)
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

        Cache.put(@stats_cache_key, stats_from_db, ttl: :timer.minutes(10))
        stats_from_db
    end
  end

end
