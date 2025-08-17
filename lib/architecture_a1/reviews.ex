defmodule ArchitectureA1.Reviews do
  @moduledoc """
  Acceso a la colección `reviews`.
  Cada review: %{_id, book_id: BSON.ObjectId.t(), score: 1..5, upvotes: integer}
  """

  # Lista todas las reviews de un libro
  def list_by_book(book_id_hex) when is_binary(book_id_hex) do
    oid = BSON.ObjectId.decode!(book_id_hex)
    Mongo.find(ArchitectureA1.Mongo, "reviews", %{book_id: oid})
    |> Enum.to_list()
  end

  # Crea una review (score 1..5)
  def create(book_id_hex, score_int, text \\ "") when is_integer(score_int) and score_int in 1..5 do
    doc = %{
      book_id: BSON.ObjectId.decode!(book_id_hex),
      text: text,
      score: score_int,
      upvotes: 0
    }

    Mongo.insert_one(ArchitectureA1.Mongo, "reviews", doc)
  end

  # Suma +1 a upvotes de una review
  def upvote(review_id_hex) do
    rid = BSON.ObjectId.decode!(review_id_hex)
    Mongo.update_one(
      ArchitectureA1.Mongo,
      "reviews",
      %{_id: rid},
      %{"$inc" => %{upvotes: 1}}
    )
  end

  # Promedio de puntajes para un libro (o nil si no hay reviews)
  def avg_for_book(book_id_hex) do
    reviews = list_by_book(book_id_hex)

    case reviews do
      [] -> nil
      _  ->
        sum = reviews |> Enum.map(&(&1["score"] || &1[:score])) |> Enum.sum()
        sum / length(reviews)
    end
  end

  # Devuelve todas las reviews de todos los libros
  def list_all do
    Mongo.find(ArchitectureA1.Mongo, "reviews", %{})
    |> Enum.map(fn r -> Map.put(r, "book_id", to_string(r["book_id"])) end)
  end

  # Devuelve una review por su id
  def get(review_id_hex) do
    rid = BSON.ObjectId.decode!(review_id_hex)
    Mongo.find_one(ArchitectureA1.Mongo, "reviews", %{_id: rid})
  end

  # Actualiza una review
 # Actualiza una review
 def update(review_id_hex, attrs) do
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
      {:ok, get(review_id_hex)}

    _ ->
      {:error, :not_found}
  end
end


def top_rated_books(limit \\ 10) do
  # Agrupamos por libro, calculando promedio
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

    # Obtener info del libro (suponiendo que está en cada review)
    book_info = %{
      title: reviews |> List.first() |> Map.get("book_title"),
      author: reviews |> List.first() |> Map.get("book_author"),
      year: reviews |> List.first() |> Map.get("book_year")
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


end
