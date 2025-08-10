defmodule ArchitectureA1.Books do
  @moduledoc """
  Technically the books controller (as we know it)
  """

  def all_books(conn) do
    Mongo.find(conn, "books", %{}) |> Enum.to_list()
  end

  def insert_sample_books(conn) do
    books = [
      %{title: "Libro Chiara", author: "Chiara Romanini", year: 2001},
      %{title: "Libro Vicho", author: "Vicente Acevedo", year: 2002},
      %{title: "Libro Fabi", author: "Fabián Saavedra", year: 2002}
    ]

    Enum.each(books, fn book ->
      Mongo.insert_one(conn, "books", book)
    end)
  end
end
