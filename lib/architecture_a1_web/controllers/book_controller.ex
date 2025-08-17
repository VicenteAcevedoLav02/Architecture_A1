defmodule ArchitectureA1Web.BookController do
  use ArchitectureA1Web, :controller

  alias ArchitectureA1.Books

  def index(conn, _params) do
    books = Books.get_all_books()
    render(conn, :index, books: books)
  end

  def new(conn, _params) do
    authors = ArchitectureA1.Authors.get_all_authors()
    render(conn, :new, authors: authors)
  end

  def create(conn, params) do
    params
    |> book_params()
    |> Books.create_book()
    |> handle_result(
      conn,
      success_path: ~p"/books",
      success_msg: "Book created successfully.",
      error_path: ~p"/books/new"
    )
  end

  def edit(conn, %{"id" => id}) do
    case Books.get_book_by_id(id) do
      nil ->
        conn
        |> put_flash(:error, "Book not found")
        |> redirect(to: ~p"/books")

      book ->
        authors = ArchitectureA1.Authors.get_all_authors()
        render(conn, :edit, book: book, authors: authors)
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = book_params(params)

    Books.update_book(id, attrs)
    |> handle_result(conn,
      success_path: ~p"/books",
      success_msg: "Book updated successfully",
      error_path: ~p"/books/#{id}/edit"
    )
  end

  def delete(conn, %{"id" => id}) do
    Books.delete_book(id)
    |> handle_result(conn,
      success_path: ~p"/books",
      success_msg: "Book deleted successfully",
      error_path: ~p"/books"
    )
  end

  def top_selling(conn, _params) do
    top_books = Books.top_selling_books()
    render(conn, :top_selling, top_books: top_books)
  end

  # Helpers

  defp book_params(params) do
    Map.drop(params, ["_csrf_token", "_method", "id"])
  end

  defp handle_result({:ok, _}, conn, opts) do
    conn
    |> put_flash(:info, opts[:success_msg])
    |> redirect(to: opts[:success_path])
  end

  defp handle_result({:error, reason}, conn, opts) do
    conn
    |> put_flash(:error, "Error: #{inspect(reason)}")
    |> redirect(to: opts[:error_path])
  end
end
