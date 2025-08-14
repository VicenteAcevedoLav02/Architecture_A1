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
    attrs = Map.drop(author_params, ["_csrf_token"])

    case Authors.create_author(attrs) do
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

  def edit(conn, %{"id" => id}) do
    author = Authors.get_all_authors()
            |> Enum.find(fn a -> a.id == id end)
    render(conn, :edit, author: author)
  end

  def update(conn, %{"id" => id} = author_params) do
    attrs =
      author_params
      |> Map.drop(["id", "_csrf_token", "_method"])

    case Authors.update_author(id, attrs) do
      {:ok, _msg} ->
        conn
        |> put_flash(:info, "Author updated successfully")
        |> redirect(to: ~p"/authors")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error updating author: #{inspect(reason)}")
        |> redirect(to: ~p"/authors/#{id}/edit")
    end
  end

end
