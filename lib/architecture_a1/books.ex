defmodule ArchitectureA1.Books do
  alias Mongo
  alias ArchitectureA1.Mongo, as: AppMongo

  def get_all_books() do
    Mongo.find(ArchitectureA1.Mongo, "books", %{})
    |> Enum.map(fn doc ->
      id = BSON.ObjectId.encode!(doc["_id"])
      Map.put(doc, :id, id)
      |> Map.delete("_id")
    end)
  end

  def get_book_by_id(id) do
    case BSON.ObjectId.decode(id) do
      {:ok, obj_id} ->
        case Mongo.find_one(ArchitectureA1.Mongo, "books", %{"_id" => obj_id}) do
          nil -> nil
          doc -> Map.put(doc, :id, BSON.ObjectId.encode!(doc["_id"]))
        end

      :error ->
        nil
    end
  end

  def create_book(attrs) do
    {:ok, result} = Mongo.insert_one(ArchitectureA1.Mongo, "books", attrs)
    {:ok, result}
  rescue
    e -> {:error, e}
  end

  def update_book(id, attrs) do
    filter = %{"_id" => BSON.ObjectId.decode!(id)}
    update = %{"$set" => attrs}

    case Mongo.update_one(ArchitectureA1.Mongo, "books", filter, update) do
      {:ok, %Mongo.UpdateResult{matched_count: 1}} ->
        {:ok, "Book updated successfully"}

      {:ok, %Mongo.UpdateResult{matched_count: 0}} ->
        {:error, "No book found with that ID"}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, e}
  end

  def delete_book(id) do
    filter = %{"_id" => BSON.ObjectId.decode!(id)}

    case Mongo.delete_one(ArchitectureA1.Mongo, "books", filter) do
      {:ok, %Mongo.DeleteResult{deleted_count: 1}} ->
        {:ok, "Book deleted successfully"}

      {:ok, %Mongo.DeleteResult{deleted_count: 0}} ->
        {:error, "No book found with that ID"}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, e}
  end

  def get_book!(book_id_hex) when is_binary(book_id_hex) do
    oid = BSON.ObjectId.decode!(book_id_hex)
    Mongo.find_one(ArchitectureA1.Mongo, "books", %{_id: oid}) ||
      raise "Book not found"
  end

  def recalculate_number_of_sales(book_id_hex) when is_binary(book_id_hex) do
    sales = ArchitectureA1.Sales.get_sales_by_book(book_id_hex)

    total =
      sales
      |> Enum.map(fn s ->
        # cases cause the value may be int or str
        case s["sales"] do
          n when is_integer(n) -> n
          n when is_binary(n) ->
            case Integer.parse(n) do
              {val, _rest} -> val
              :error -> 0
            end
          _ -> 0
        end
      end)
      |> Enum.sum()

    update_book(book_id_hex, %{"number_of_sales" => total})
  end

  def search(query, page \\ 1, page_size \\ 20) do
    search_terms =
      String.split(query, " ", trim: true)
      |> Enum.reject(& &1 == "")

    if Enum.empty?(search_terms) do
      {:ok, []}
    else
      match_terms =
        search_terms
        |> Enum.map(fn term -> %{"summary" => %{"$regex" => term, "$options" => "i"}} end)

      pipeline = [
        %{"$match" => %{"$and" => match_terms}},
        %{"$skip" => (page - 1) * page_size},
        %{"$limit" => page_size}
      ]

      case Mongo.aggregate(AppMongo, "books", pipeline) do
        {:ok, mongo_stream} ->
          books = mongo_stream |> Enum.to_list()
          authors = ArchitectureA1.Authors.get_all_authors()

          authors_map =
            authors
            |> Enum.into(%{}, fn author ->
              {(author[:id]), author}
            end)

          books_with_authors =
            Enum.map(books, fn book ->
              author_id = book["author_id"]
              author = Map.get(authors_map, author_id)

              author_name = if author, do: author["name"], else: "Unknown Author"
              Map.put(book, "author_name", author_name)
            end)

          {:ok, books_with_authors}
        %Mongo.Stream{} = mongo_stream ->
          books = mongo_stream |> Enum.to_list()
          authors = ArchitectureA1.Authors.get_all_authors()
          authors_map =
            authors
            |> Enum.into(%{}, fn author ->
              {(author[:id]), author}
            end)

          books_with_authors =
            Enum.map(books, fn book ->
              author_id = book["author_id"]
              author = Map.get(authors_map, author_id)
              author_name = if author, do: author["name"], else: "Unknown Author"
              Map.put(book, "author_name", author_name)
            end)

          {:ok, books_with_authors}
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def top_selling_books() do
    books = get_all_books()

    top_books =
      books
      |> Enum.sort_by(fn b ->
        case b["number_of_sales"] do
          n when is_integer(n) -> n
          n when is_binary(n) ->
            case Integer.parse(n) do
              {val, _} -> val
              :error -> 0
            end
          _ -> 0
        end
      end, :desc)
      |> Enum.take(50)

    authors_stats = ArchitectureA1.Authors.list_authors_stats()

    # Marcando si el libro estuvo en el top 5 el año de publicación
    Enum.map(top_books, fn book ->
      year =
        case book["date_of_publication"] do
          nil -> nil
          date when is_binary(date) ->
            String.slice(date, 0, 4) # "2025-08-13" -> "2025"
          _ -> nil
        end

      top_5_for_year =
        ArchitectureA1.Sales.get_top_n_by_year(year, 5)
        |> Enum.map(& &1["book_id"])

      author_total =
        case Enum.find(authors_stats, fn a -> a.id == book["author_id"] end) do
          nil -> 0
          a -> a.total_sales
        end

      %{
        id: book.id,
        author_id: book["author_id"],
        title: book["title"],
        number_of_sales: book["number_of_sales"],
        author_total_sales: author_total,
        top5_in_year?: book.id in top_5_for_year
      }
    end)
  end
end
