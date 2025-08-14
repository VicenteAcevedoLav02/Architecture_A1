defmodule ArchitectureA1Web.AuthorController do
  use ArchitectureA1Web, :controller

  alias ArchitectureA1.Authors

  def index(conn, _params) do
    authors = Authors.get_all_authors()
    render(conn, :index, authors: authors)
  end

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, author_params) do
    case Authors.create_author(author_params) do
      {:ok, _author} ->
        conn
        |> put_flash(:info, "Author created successfully.")
        |> redirect(to: ~p"/authors")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error creating author: #{inspect(reason)}")
        |> redirect(to: ~p"/authors/new")
    end
  end

end
