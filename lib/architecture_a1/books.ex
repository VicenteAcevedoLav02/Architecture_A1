defmodule ArchitectureA1.Books do
  @moduledoc """
  Technically the books controller (as we know it)
  """

  def all_books do
    Mongo.find(ArchitectureA1.Mongo, "books", %{}) |> Enum.to_list()
  end

  def insert_sample_books do
    books = [
      %{title: "Libro Chiara", author: "Chiara Romanini", year: 2001},
      %{title: "Libro Vicho", author: "Vicente Acevedo", year: 2002},
      %{title: "Libro Fabi", author: "Fabián Saavedra", year: 2002}
    ]

    Enum.each(books, fn book ->
      Mongo.insert_one(ArchitectureA1.Mongo, "books", book)
    end)
  end
end
