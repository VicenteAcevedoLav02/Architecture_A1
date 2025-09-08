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

  def create(conn, params) do
    # Procesar cover si existe
    params =
      case params["photo"] do
        %Plug.Upload{filename: filename, path: tmp_path} ->
          storage_dir = Application.get_env(:architecture_a1, :upload_path, "priv/static/uploads")
          File.mkdir_p!(storage_dir)

          unique_filename = "#{Ecto.UUID.generate()}_#{filename}"
          dest_path = Path.join(storage_dir, unique_filename)
          File.cp!(tmp_path, dest_path)

          params
          |> Map.put("photo_url", "/uploads/#{unique_filename}")
          |> Map.delete("photo") # <- clave eliminada correctamente
        _ ->
          params
      end
    # Llamamos a tu capa de persistencia (Books)
    Authors.create_author(params)
    |> handle_result(
      conn,
      success_path: ~p"/authors",
      success_msg: "Author created successfully.",
      error_path: ~p"/authors/new"
    )
  end

  def edit(conn, %{"id" => id}) do
    case Authors.get_author_by_id(id) do
      nil ->
        conn
        |> put_flash(:error, "Author not found")
        |> redirect(to: ~p"/authors")

      author ->
        render(conn, :edit, author: author)
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = author_params(params)

    Authors.update_author(id, attrs)
    |> handle_result(conn,
      success_path: ~p"/authors",
      success_msg: "Author updated successfully",
      error_path: ~p"/authors/#{id}/edit"
    )
  end

  def delete(conn, %{"id" => id}) do
    Authors.delete_author(id)
    |> handle_result(conn,
      success_path: ~p"/authors",
      success_msg: "Author deleted successfully",
      error_path: ~p"/authors"
    )
  end

  def stats(conn, _params) do
    authors_stats = Authors.list_authors_stats()
    render(conn, :stats, authors_stats: authors_stats)
  end

  defp author_params(params) do
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
