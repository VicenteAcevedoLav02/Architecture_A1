defmodule ArchitectureA1.Reviews do
  @moduledoc """
  Acceso a la colección `reviews`.
  Cada review: %{_id, book_id: BSON.ObjectId.t(), score: 1..5, upvotes: integer}
  """

  require Logger

  alias ArchitectureA1.Books
  alias ArchitectureA1.Authors
  alias ArchitectureA1.Cache

  # --- Claves de Caché ---
  defp review_cache_key(id), do: "review:#{id}"
  defp reviews_for_book_key(book_id), do: "reviews:for_book:#{book_id}"
  defp avg_score_for_book_key(book_id), do: "reviews:avg_score_for_book:#{book_id}"
  @top_rated_books_key "reviews:top_rated_books"

  # Lista todas las reviews de un libro
  def list_by_book(book_id_hex) when is_binary(book_id_hex) do
    cache_key = reviews_for_book_key(book_id_hex)
    case Cache.get(cache_key) do
      reviews when is_list(reviews) ->
        reviews
      nil ->
        oid = BSON.ObjectId.decode!(book_id_hex)
        reviews_from_db =
          Mongo.find(ArchitectureA1.Mongo, "reviews", %{book_id: oid})
          |> Enum.to_list()

        Cache.put(cache_key, reviews_from_db, ttl: :timer.hours(1))
        reviews_from_db
    end
  end

  def create(book_id_hex, score_int, text \\ "") when is_integer(score_int) and score_int in 1..5 do
    doc = %{
      book_id: BSON.ObjectId.decode!(book_id_hex),
      text: text,
      score: score_int,
      upvotes: 0
    }

    case Mongo.insert_one(ArchitectureA1.Mongo, "reviews", doc) do
      {:ok, result} ->
        review_id = BSON.ObjectId.encode!(result.inserted_id)
        created_review = get(review_id)

        ArchitectureA1.OpenSearch.index_review(created_review)

        Cache.delete(reviews_for_book_key(book_id_hex))
        Cache.delete(avg_score_for_book_key(book_id_hex))
        Cache.delete(@top_rated_books_key)
        Authors.invalidate_stats_cache()

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Suma +1 a upvotes de una review
  def upvote(review_id_hex) do
    with %{"book_id" => book_id} <- get(review_id_hex) do
      rid = BSON.ObjectId.decode!(review_id_hex)

      case Mongo.update_one(ArchitectureA1.Mongo, "reviews", %{_id: rid}, %{"$inc" => %{upvotes: 1}}) do
        {:ok, %{matched_count: 1}} = success ->
          book_id_hex = to_string(book_id)
          Cache.delete(review_cache_key(review_id_hex))
          Cache.delete(reviews_for_book_key(book_id_hex))
          Cache.delete(@top_rated_books_key)
          # Nota: No invalidamos `avg_score` ni `authors:stats` porque un upvote no cambia el puntaje.
          success
        other ->
          other
      end
    else
      _ -> {:error, :not_found}
    end
  end

  # Promedio de puntajes para un libro (o nil si no hay reviews)
  def avg_for_book(book_id_hex) do
    cache_key = avg_score_for_book_key(book_id_hex)
    case Cache.get(cache_key) do
      avg when is_number(avg) or is_nil(avg) ->
        avg
      nil ->
        reviews = list_by_book(book_id_hex)
        avg_score =
          case reviews do
            [] -> nil
            _  ->
              sum = reviews |> Enum.map(&(&1["score"] || &1[:score])) |> Enum.sum()
              sum / length(reviews)
          end
        Cache.put(cache_key, avg_score, ttl: :timer.hours(1))
        avg_score
    end
  end

  # Devuelve todas las reviews de todos los libros
  def list_all do
    Mongo.find(ArchitectureA1.Mongo, "reviews", %{})
    |> Enum.map(fn r -> Map.put(r, "book_id", to_string(r["book_id"])) end)
  end

  # Devuelve una review por su id
  def get(review_id_hex) do
    cache_key = review_cache_key(review_id_hex)
    case Cache.get(cache_key) do
      review when is_map(review) ->
        review
      nil ->
        rid = BSON.ObjectId.decode!(review_id_hex)
        review_from_db = Mongo.find_one(ArchitectureA1.Mongo, "reviews", %{_id: rid})
        if review_from_db, do: Cache.put(cache_key, review_from_db, ttl: :timer.hours(1))
        review_from_db
    end
  end


  def update(review_id_hex, attrs) do
    with %{"book_id" => book_id} <- get(review_id_hex) do
      rid = BSON.ObjectId.decode!(review_id_hex)
      {:ok, result} =
        Mongo.update_one(
          ArchitectureA1.Mongo,
          "reviews",
          %{_id: rid},
          %{"$set" => attrs}
        )
      case result do
        %{matched_count: 1} ->
          updated_review = get(review_id_hex)
          ArchitectureA1.OpenSearch.index_review(updated_review)
          book_id_hex = to_string(book_id)
          Cache.delete(review_cache_key(review_id_hex))
          Cache.delete(reviews_for_book_key(book_id_hex))
          Cache.delete(avg_score_for_book_key(book_id_hex))
          Cache.delete(@top_rated_books_key)
          Authors.invalidate_stats_cache()
          {:ok, updated_review}
        _ ->
          {:error, :not_found}
      end
    end
  end

  def delete(review_id) do
    review_id_hex = to_string(review_id)
    with %{"book_id" => book_id} <- get(review_id_hex) do
      rid =
        case review_id do
          %BSON.ObjectId{} -> review_id
          id when is_binary(id) -> BSON.ObjectId.decode!(id)
        end

      case Mongo.delete_one(ArchitectureA1.Mongo, "reviews", %{_id: rid}) do
        {:ok, %Mongo.DeleteResult{deleted_count: 1}} ->
          book_id_hex = to_string(book_id)

          Cache.delete(review_cache_key(review_id_hex))
          Cache.delete(reviews_for_book_key(book_id_hex))
          Cache.delete(avg_score_for_book_key(book_id_hex))
          Cache.delete(@top_rated_books_key)

          Authors.invalidate_stats_cache()

          ArchitectureA1.OpenSearch.delete_review(to_string(rid))
          {:ok, "Review deleted successfully"}

        {:ok, %Mongo.DeleteResult{deleted_count: 0}} ->
          {:error, "No review found with that ID"}

        {:error, reason} ->
          {:error, reason}
      end
    else
      # Esto se ejecuta si la función `get(review_id_hex)` devuelve nil
      _ -> {:error, "No review found with that ID"}
    end
  end

  def top_rated_books(limit \\ 10) do
    if limit != 10 do
      # Si el límite es diferente, calculamos sin caché.
      calculate_top_rated_books(limit)
    end

    case Cache.get(@top_rated_books_key) do
      # CACHE HIT:
      top_books when is_list(top_books) ->
        top_books

      # CACHE MISS:
      nil ->
        result = calculate_top_rated_books(limit)

        Cache.put(@top_rated_books_key, result, ttl: :timer.minutes(30))
        result
    end
  end

  defp calculate_top_rated_books(limit) do
    books = Books.get_all_books()
    authors = Authors.get_all_authors()

    pipeline = [
      %{"$group" => %{
        "_id" => "$book_id",
        "avg_score" => %{"$avg" => "$score"},
        "reviews" => %{"$push" => "$$ROOT"}
      }},
      %{"$sort" => %{"avg_score" => -1}},
      %{"$limit" => limit}
    ]

    Mongo.aggregate(ArchitectureA1.Mongo, "reviews", pipeline)
    |> Enum.map(fn book_group ->
      reviews = book_group["reviews"]

      highest_review = Enum.max_by(reviews, &(&1["score"]), fn -> %{"score" => 0, "text" => "", "upvotes" => 0} end)
      lowest_review  = Enum.min_by(reviews, &(&1["score"]), fn -> %{"score" => 0, "text" => "", "upvotes" => 0} end)

      book_id = to_string(List.first(reviews)["book_id"])
      book = Enum.find(books, fn b -> to_string(b[:id]) == book_id end)

      author = Enum.find(authors, fn a -> to_string(a[:id]) == book["author_id"] end)
      author_name = author["name"]

      book_info = %{
        title: book["title"],
        author: author_name,
        year: book["date_of_publication"]
      }

      %{
        book: book_info,
        avg_score: book_group["avg_score"],
        highest_review: highest_review,
        lowest_review: lowest_review
      }
    end)
  end



  def decode_id(id) do
    case BSON.ObjectId.decode(id) do
      {:ok, object_id} -> {:ok, object_id}
      :error -> {:error, :invalid_id}
    end
  end

  def invalidate_top_rated_cache() do
    Cache.delete(@top_rated_books_key)
  end


end
