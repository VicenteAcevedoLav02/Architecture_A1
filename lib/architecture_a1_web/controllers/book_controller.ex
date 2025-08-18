defmodule ArchitectureA1Web.BookController do
  use ArchitectureA1Web, :controller

  alias ArchitectureA1.Books


  def index(conn, _params) do
    IO.puts("➡️ Entrando en BooksController.index")

    books = Books.get_all_books()
    IO.inspect(books, label: "📚 Books obtenidos")

    # Mostrar todas las ventas en la colección
    all_sales =
      Mongo.find(ArchitectureA1.Mongo, "sales", %{})
      |> Enum.to_list()

    IO.inspect(all_sales, label: "💵 Todas las ventas en Mongo")

    books_with_sales =
      Enum.map(books, fn book ->
        IO.inspect(book, label: "🔎 Procesando book")

        book_oid =
          case book["_id"] || book.id do
            %BSON.ObjectId{} = oid -> oid
            id when is_binary(id) -> BSON.ObjectId.decode!(id)
          end

        sales =
          Mongo.find(ArchitectureA1.Mongo, "sales", %{book_id: book_oid})
          |> Enum.to_list()
        IO.inspect(sales, label: "💰 Ventas encontradas para este book")

        total_sales =
          sales
          |> Enum.map(& &1["sales"])
          |> Enum.sum()

        IO.inspect(total_sales, label: "📊 Total de ventas\n")

        Map.put(book, "sales", sales)
        |> Map.put("number_of_sales", total_sales)
      end)

    IO.inspect(books_with_sales, label: "✅ Books enriquecidos con sales")

    render(conn, :index, books: books_with_sales)
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

  def search(conn, params) do
    query = Map.get(params, "query", "")
    page =
      case Map.get(params, "page", "1") do
        page_str ->
          case Integer.parse(page_str) do
            {int, _} -> int
            :error -> 1
          end
      end

    if query == "" do
      conn
      |> put_flash(:info, "Please enter a search term.")
      |> render(:search, search_results: [], query: "", page: 1)
    else
      case Books.search(query, page) do
        {:ok, books} ->
          render(conn, :search,
            search_results: books,
            query: query,
            page: page
          )
        {:error, reason} ->
          conn
          |> put_flash(:error, "Error: #{inspect(reason)}")
          |> redirect(to: ~p"/books/search")
      end
    end
  end

  def top_selling(conn, _params) do
    IO.puts("➡️ Entrando en BooksController.top_selling")

    # Obtener los libros top según tu función actual
    top_books = Books.top_selling_books()
    # Enriquecer cada libro con sus ventas y las ventas del autor
    top_books_with_sales =
      Enum.map(top_books, fn book ->

        # Convertir el id del libro a ObjectId si es necesario
        book_object_id =
          case book[:id] || book["id"] do
            %BSON.ObjectId{} = oid -> oid
            id when is_binary(id) -> BSON.ObjectId.decode!(id)
          end

        # Obtener todas las ventas asociadas a este libro
        sales =
          Mongo.find(ArchitectureA1.Mongo, "sales", %{book_id: book_object_id})
          |> Enum.to_list()

        # Sumar ventas del libro
        total_sales =
          sales
          |> Enum.map(& &1["sales"])
          |> Enum.sum()
        # Calcular ventas totales del autor
        IO.inspect(book, label: "Keys del book")

        author_id =
          case Map.get(book, :author_id) || Map.get(book, "author_id") do
            %BSON.ObjectId{} = oid -> oid
            id when is_binary(id) -> BSON.ObjectId.decode!(id)
            nil ->
              IO.puts("⚠️ Este book no tiene author_id: #{inspect(book)}")
              nil
          end

        IO.inspect(author_id, label: "AUTOR!!!")

        # Obtener todos los libros del autor
        author_books =
          Mongo.find(ArchitectureA1.Mongo, "books", %{author_id: author_id})
          |> Enum.to_list()

        # Sumar todas las ventas de los libros del autor
        author_total_sales =
          author_books
          |> Enum.map(fn b ->
            book_oid = b["_id"]
            Mongo.find(ArchitectureA1.Mongo, "sales", %{book_id: book_oid})
            |> Enum.to_list()
            |> Enum.map(& &1["sales"])
            |> Enum.sum()
          end)
          |> Enum.sum()

        IO.inspect(author_total_sales, label: "👤 Total de ventas del autor")

        # Añadir los atributos sales, number_of_sales y author_total_sales al libro
        book
        |> Map.put("sales", sales)
        |> Map.put("number_of_sales", total_sales)
        |> Map.put("author_total_sales", author_total_sales)
      end)

    IO.inspect(top_books_with_sales, label: "✅ Top books enriquecidos con sales y ventas del autor")

    render(conn, :top_selling, top_books: top_books_with_sales)
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
