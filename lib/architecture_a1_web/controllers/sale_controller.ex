defmodule ArchitectureA1Web.SaleController do
  use ArchitectureA1Web, :controller

  alias ArchitectureA1.Sales

  def index(conn, _params) do
    sales = Sales.get_all_sales()
    books = ArchitectureA1.Books.get_all_books()
    render(conn, :index, sales: sales, books: books)
  end

  def new(conn, _params) do
    books = ArchitectureA1.Books.get_all_books()
    render(conn, :new, books: books)
  end

  def create(conn, params) do
    params
    |> sale_params()
    |> Sales.create_sale()
    |> handle_result(
      conn,
      success_path: ~p"/sales",
      success_msg: "Sale created successfully.",
      error_path: ~p"/sales/new"
    )
  end

  def edit(conn, %{"id" => id}) do
    case Sales.get_sale_by_id(id) do
      nil ->
        conn
        |> put_flash(:error, "Sale not found")
        |> redirect(to: ~p"/sales")

      sale ->
        books = ArchitectureA1.Books.get_all_books()
        render(conn, :edit, sale: sale, books: books)
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = sale_params(params)

    Sales.update_sale(id, attrs)
    |> handle_result(conn,
      success_path: ~p"/sales",
      success_msg: "Sale updated successfully",
      error_path: ~p"/sales/#{id}/edit"
    )
  end

  def delete(conn, %{"id" => id}) do
    Sales.delete_sale(id)
    |> handle_result(conn,
      success_path: ~p"/sales",
      success_msg: "Sale deleted successfully",
      error_path: ~p"/sales"
    )
  end

  # Helpers

  defp sale_params(params) do
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
