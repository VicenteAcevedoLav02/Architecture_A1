defmodule ArchitectureA1.OpenSearch do

  require Logger

  @opensearch_url "http://opensearch:9200"
  @books_index "books"
  @reviews_index "reviews"

  def available? do
    case Req.get(@opensearch_url, connect_options: [timeout: 1000]) do
      {:ok, %{status: 200}} -> true
      _ -> false
    end
  end

  def setup_indices do
    if available?() do
      create_books_index()
      create_reviews_index()
      {:ok, "Indices created"}
    else
      {:error, "OpenSearch not available"}
    end
  end

  defp create_books_index do
    mapping = %{
      mappings: %{
        properties: %{
          title: %{type: "text"},
          summary: %{type: "text"},
          author_id: %{type: "keyword"},
          date_of_publication: %{type: "date", format: "yyyy-MM-dd||yyyy"},
          number_of_sales: %{type: "integer"}
        }
      }
    }

    Req.put("#{@opensearch_url}/#{@books_index}", json: mapping)
  end

  defp create_reviews_index do
    mapping = %{
      mappings: %{
        properties: %{
          book_id: %{type: "keyword"},
          text: %{type: "text"},
          score: %{type: "integer"},
          upvotes: %{type: "integer"}
        }
      }
    }

    Req.put("#{@opensearch_url}/#{@reviews_index}", json: mapping)
  end

  def search_books(query, page \\ 1, page_size \\ 20) do
    if not available?() do
      {:error, "OpenSearch not available"}
    else
      search_query = %{
        query: %{
          multi_match: %{
            query: query,
            fields: ["title^2", "summary"],
            type: "best_fields",
            fuzziness: "AUTO"
          }
        },
        from: (page - 1) * page_size,
        size: page_size
      }

      case Req.post("#{@opensearch_url}/#{@books_index}/_search", json: search_query) do
        {:ok, %{status: 200, body: response}} ->
          books =
            response["hits"]["hits"]
            |> Enum.map(fn hit ->
              hit["_source"]
              |> Map.put("id", hit["_id"])
            end)
          {:ok, books}

        {:error, reason} ->
          {:error, reason}

        _ ->
          {:error, "Search failed"}
      end
    end
  end

  def index_book(book) do
    if available?() do
      doc = %{
        title: book["title"],
        summary: book["summary"],
        author_id: book["author_id"],
        date_of_publication: book["date_of_publication"],
        number_of_sales: book["number_of_sales"] || 0
      }

      book_id = book[:id] || book["id"] || BSON.ObjectId.encode!(book["_id"])

      case Req.put("#{@opensearch_url}/#{@books_index}/_doc/#{book_id}", json: doc) do
        {:ok, %{status: status}} when status in [200, 201] ->
          # Logger.info("Book indexed successfully: #{book_id}")
          :ok
        {:error, reason} ->
          # Logger.error("Failed to index book: #{inspect(reason)}")
          :error
        _ ->
          # Logger.error("Unexpected response when indexing book")
          :error
      end
    else
      :ok
    end
  end

  def index_review(review) do
    if available?() do
      doc = %{
        book_id: to_string(review["book_id"]),
        text: review["text"] || "",
        score: review["score"],
        upvotes: review["upvotes"] || 0
      }

      review_id = BSON.ObjectId.encode!(review["_id"])

      case Req.put("#{@opensearch_url}/#{@reviews_index}/_doc/#{review_id}", json: doc) do
        {:ok, %{status: status}} when status in [200, 201] ->
          # Logger.info("Review indexed successfully: #{review_id}")
          :ok
        {:error, reason} ->
          # Logger.error("Failed to index review: #{inspect(reason)}")
          :error
        _ ->
          :error
      end
    else
      :ok
    end
  end

  def delete_book(book_id) do
    if available?() do
      case Req.delete("#{@opensearch_url}/#{@books_index}/_doc/#{book_id}") do
        {:ok, %{status: status}} when status in [200, 404] ->
          # Logger.info("Book deleted from search: #{book_id}")
          :ok
        _ ->
          :error
      end
    else
      :ok
    end
  end

  def delete_review(review_id) do
    if available?() do
      case Req.delete("#{@opensearch_url}/#{@reviews_index}/_doc/#{review_id}") do
        {:ok, %{status: status}} when status in [200, 404] ->
          :ok
        _ ->
          :error
      end
    else
      :ok
    end
  end

  def sync_all_books do
    if available?() do
      books = ArchitectureA1.Books.get_all_books()
      # Logger.info("Syncing #{length(books)} books to OpenSearch...")

      results = Enum.map(books, &index_book/1)
      successful = Enum.count(results, &(&1 == :ok))

      {:ok, "Synced #{successful}/#{length(books)} books"}
    else
      {:error, "OpenSearch not available"}
    end
  end

  def sync_all_reviews do
    if available?() do
      reviews = ArchitectureA1.Reviews.list_all()
      # Logger.info("Syncing #{length(reviews)} reviews to OpenSearch...")

      results = Enum.map(reviews, &index_review/1)
      successful = Enum.count(results, &(&1 == :ok))

      {:ok, "Synced #{successful}/#{length(reviews)} reviews"}
    else
      {:error, "OpenSearch not available"}
    end
  end
end
