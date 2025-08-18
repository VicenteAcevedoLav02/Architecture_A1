defmodule ArchitectureA1Web.ReviewController do
  use ArchitectureA1Web, :controller

  alias ArchitectureA1.Books
  alias ArchitectureA1.Reviews
  alias ArchitectureA1.Authors

  # /books/:book_id/reviews (GET)
  def index(conn, %{"book_id" => book_id}) do
    book    = Books.get_book!(book_id)
    reviews = Reviews.list_by_book(book_id)
    avg     = Reviews.avg_for_book(book_id)

    render(conn, :index, book: book, reviews: reviews, avg: avg)
  end

  # /books/:book_id/reviews (POST)
  def create(conn, %{"book_id" => book_id, "score" => score_param, "text" => text}) do
    with {score_int, ""} <- Integer.parse(score_param),
         true <- score_int in 1..5,
         {:ok, _} <- Reviews.create(book_id, score_int, text) do
          conn
          |> put_flash(:info, "Review created successfully.")
          |> redirect(to: "/books/#{book_id}/reviews")

    else
      :error ->
        conn
        |> put_flash(:error, "Error creating review.")
        |> redirect(to: "/books/#{book_id}/reviews")

      false ->
        conn
        |> put_flash(:error, "Error creating review.")
        |> redirect(to: "/books/#{book_id}/reviews")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error creating review.")
        |> redirect(to: "/books/#{book_id}/reviews")
    end
  end

  # /books/:book_id/reviews/:id/upvote (POST)
  def upvote(conn, %{"book_id" => book_id, "id" => review_id}) do
    Reviews.upvote(review_id)
    redirect(conn, to: "/books/#{book_id}/reviews")
  end

  # Devuelve todas las reviews de todos los libros
  def all_reviews(conn, _params) do
    authors = Authors.get_all_authors()
    books = Books.get_all_books()
    reviews = Reviews.list_all()
    top_books = Reviews.top_rated_books(10)

    reviews_with_books = Enum.map(reviews, fn review ->
      book = Enum.find(books, fn b -> to_string(b[:id]) == review["book_id"] end)

      author_name = if book, do: Enum.find_value(authors, fn a ->
        if a[:id] == book["author_id"], do: a["name"], else: nil
      end), else: nil

      book = if book, do: Map.put(book, :author_name, author_name), else: nil
      Map.put(review, :book, book)
    end)

    render(conn, :home, reviews: reviews_with_books, top_books: top_books)
  end

  # GET /books/:book_id/reviews/:id/edit
  def edit(conn, %{"book_id" => book_id, "id" => review_id}) do
    review = Reviews.get(review_id)
    book = Books.get_book!(book_id)
    render(conn, :edit, book: book, review: review)
  end

  # PUT /books/:book_id/reviews/:id
  def update(conn, %{"book_id" => book_id, "id" => review_id, "score" => score_param, "text" => text}) do
    with {score_int, ""} <- Integer.parse(score_param),
        true <- score_int in 1..5,
        {:ok, _} <- Reviews.update(review_id, %{score: score_int, text: text}) do
          conn
          |> put_flash(:info, "Review updated successfully.")
          |> redirect(to: "/books/#{book_id}/reviews")
    else
      :error ->
        conn
        |> put_flash(:error, "Error updating review.")
        |> redirect(to: "/books/#{book_id}/reviews")
      false ->
        conn
        |> put_flash(:error, "Error updating review.")
        |> redirect(to: "/books/#{book_id}/reviews")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error updating review.")
        |> redirect(to: "/books/#{book_id}/reviews")
    end
  end

  def delete(conn, %{"book_id" => book_id, "id" => review_id}) do
    # Decodifica el ObjectId
    decoded_id = BSON.ObjectId.decode!(review_id)

    # Borra la review de la colección
    Mongo.delete_one!(ArchitectureA1.Mongo, "reviews", %{_id: decoded_id})

    # Redirige de vuelta a las reviews del libro
    conn
    |> put_flash(:info, "Review deleted successfully.")
    |> redirect(to: "/books/#{book_id}/reviews")
  end
end
