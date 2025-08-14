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
  def create(book_id_hex, score_int) when is_integer(score_int) and score_int in 1..5 do
    doc = %{
      book_id: BSON.ObjectId.decode!(book_id_hex),
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
end
