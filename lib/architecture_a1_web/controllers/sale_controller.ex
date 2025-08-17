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
    attrs = sale_params(params)

    result =
      case Sales.create_sale(attrs) do
        {:ok, _} = ok ->
          # Recalculate the total of the affected book
          ArchitectureA1.Books.recalculate_number_of_sales(attrs["book_id"])
          ok

        {:error, _} = err ->
          err
      end

    handle_result(
      result,
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
    old_sale = Sales.get_sale_by_id(id)
    old_book_id = old_sale && old_sale["book_id"]

    result =
      case Sales.update_sale(id, attrs) do
        {:ok, _} = ok ->
          # If the book_id changed, we do the math for both of them
          new_book_id = Map.get(attrs, "book_id", old_book_id)
          if new_book_id, do: ArchitectureA1.Books.recalculate_number_of_sales(new_book_id)
          if old_book_id && old_book_id != new_book_id do
            ArchitectureA1.Books.recalculate_number_of_sales(old_book_id)
          end
          ok

        {:error, _} = err ->
          err
      end

    handle_result(
      result,
      conn,
      success_path: ~p"/sales",
      success_msg: "Sale updated successfully",
      error_path: ~p"/sales/#{id}/edit"
    )
  end

  def delete(conn, %{"id" => id}) do
    sale = Sales.get_sale_by_id(id)
    book_id = sale && sale["book_id"]

    result =
      case Sales.delete_sale(id) do
        {:ok, _} = ok ->
          if book_id, do: ArchitectureA1.Books.recalculate_number_of_sales(book_id)
          ok

        {:error, _} = err ->
          err
      end

    handle_result(
      result,
      conn,
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
    # Re-render with books in new/edit if it fails
    conn =
      case opts[:error_path] do
        "/sales/new" ->
          books = ArchitectureA1.Books.get_all_books()
          conn
          |> put_flash(:error, "Error: #{inspect(reason)}")
          |> render(:new, books: books)

        _ ->
          conn
          |> put_flash(:error, "Error: #{inspect(reason)}")
          |> redirect(to: opts[:error_path])
      end

    conn
  end
end
