defmodule ArchitectureA1Web.SeedController do
  use ArchitectureA1Web, :controller
  alias ArchitectureA1.{Authors, Books, Reviews, Sales}
  alias BSON.ObjectId

  def seed_data(conn, _params) do
    Mongo.delete_many(ArchitectureA1.Mongo, "authors", %{})
    Mongo.delete_many(ArchitectureA1.Mongo, "books", %{})
    Mongo.delete_many(ArchitectureA1.Mongo, "reviews", %{})
    Mongo.delete_many(ArchitectureA1.Mongo, "sales", %{})

    # AUTHORS
    authors = for i <- 1..50 do
      name = "Author #{i}"
      date_of_birth = ~D[1980-01-01] |> Date.add(:rand.uniform(365*40)) |> Date.to_string()
      country_of_origin = "Country #{:rand.uniform(50)}"
      description = "Biography of #{name}"

      {:ok, res} = Mongo.insert_one(ArchitectureA1.Mongo, "authors", %{
        name: name,
        date_of_birth: date_of_birth,
        country_of_origin: country_of_origin,
        description: description
      })

      %{
        id: res.inserted_id,
        name: name,
        date_of_birth: date_of_birth,
        country_of_origin: country_of_origin,
        description: description
      }
    end

    # BOOKS
    books = for i <- 1..300 do
      author = Enum.random(authors)
      title = "Book #{i}"
      summary = "Summary for #{title}"

      date_of_publication =
        ~D[2015-01-01]
        |> Date.add(:rand.uniform(365*10))
        |> Date.to_iso8601()

      author_id =
        case author.id do
          %BSON.ObjectId{} = oid -> BSON.ObjectId.encode!(oid)
          id when is_binary(id) -> id
        end

      {:ok, res} = Mongo.insert_one(ArchitectureA1.Mongo, "books", %{
        title: title,
        summary: summary,
        date_of_publication: date_of_publication,
        author_id: author_id
      })

      %{
        title: title,
        summary: summary,
        date_of_publication: date_of_publication,
        author_id: author_id,
        id:
          case res.inserted_id do
            %BSON.ObjectId{} = oid -> BSON.ObjectId.encode!(oid)
            id when is_binary(id) -> id
          end
      }
    end

    # REVIEWS
    for book <- books do
      n_reviews = :rand.uniform(10)
      for _ <- 1..n_reviews do
        score = :rand.uniform(5)
        text = "Review #{:rand.uniform(1000)}"

        book_oid = BSON.ObjectId.decode!(book.id)

        Mongo.insert_one(ArchitectureA1.Mongo, "reviews", %{
          book_id: book_oid,
          score: score,
          text: text,
          upvotes: :rand.uniform(10) - 1
        })
      end
    end

    # SALES
    current_year = Date.utc_today().year

    for book <- books do
      for y <- (current_year-4)..current_year do
        sales_count = :rand.uniform(1000)

        Mongo.insert_one(ArchitectureA1.Mongo, "sales", %{
          book_id: book.id |> to_string(),
          year: Integer.to_string(y),
          sales: Integer.to_string(sales_count)
        })
      end
    end

    for book <- books do
      ArchitectureA1.Books.recalculate_number_of_sales(book.id |> to_string())
    end

    conn
    |> put_flash(:info, "Seed successfully completed. Generated Authors, Books, Reviews and Sales.")
    |> redirect(to: "/")
  end
end
