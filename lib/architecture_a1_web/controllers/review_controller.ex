defmodule ArchitectureA1Web.ReviewController do
  use ArchitectureA1Web, :controller

  alias ArchitectureA1.Books
  alias ArchitectureA1.Reviews

  # /books/:book_id/reviews (GET)
  def index(conn, %{"book_id" => book_id}) do
    book    = Books.get_book!(book_id)
    reviews = Reviews.list_by_book(book_id)
    avg     = Reviews.avg_for_book(book_id)

    render(conn, :index, book: book, reviews: reviews, avg: avg)
  end

  # /books/:book_id/reviews (POST)
  def create(conn, %{"book_id" => book_id, "score" => score_param}) do
    with {score_int, ""} <- Integer.parse(score_param),
         true <- score_int in 1..5,
         {:ok, _} <- Reviews.create(book_id, score_int) do
      redirect(conn, to: "/books/#{book_id}/reviews")
    else
      _ ->
        conn
        |> put_status(400)
        |> text("Score inválido (debe ser 1..5)")
    end
  end

  # /books/:book_id/reviews/:id/upvote (POST)
  def upvote(conn, %{"book_id" => book_id, "id" => review_id}) do
    Reviews.upvote(review_id)
    redirect(conn, to: "/books/#{book_id}/reviews")
  end
end
