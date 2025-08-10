defmodule ArchitectureA1Web.BookController do
  use ArchitectureA1Web, :controller

  alias ArchitectureA1.Mongo
  alias ArchitectureA1.Books

  def index(conn, _params) do
    {:ok, mongo_conn} = Mongo.start_link()
    books = Books.all_books(mongo_conn)
    render(conn, :index, books: books)
  end

  def seed(conn, _params) do
    {:ok, mongo_conn} = Mongo.start_link()
    Books.insert_sample_books(mongo_conn)
    text(conn, "Base de datos poblada con libros de ejemplo.")
  end
end
