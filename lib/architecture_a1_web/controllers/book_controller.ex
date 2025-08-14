defmodule ArchitectureA1Web.BookController do
  use ArchitectureA1Web, :controller

  alias ArchitectureA1.Books

  def index(conn, _params) do
    books = Books.all_books()
    render(conn, :index, books: books)
  end

  @spec seed(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def seed(conn, _params) do
    Books.insert_sample_books
    text(conn, "Base de datos poblada con libros de ejemplo.")
  end
end
