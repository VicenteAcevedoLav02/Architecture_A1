defmodule ArchitectureA1Web.SeedController do
  use ArchitectureA1Web, :controller
  alias ArchitectureA1.{Authors, Books, Reviews, Sales}
  alias BSON.ObjectId

  def seed_data(conn, _params) do
    # Limpiar colecciones (opcional)
    Mongo.delete_many(ArchitectureA1.Mongo, "authors", %{})
    Mongo.delete_many(ArchitectureA1.Mongo, "books", %{})
    Mongo.delete_many(ArchitectureA1.Mongo, "reviews", %{})
    Mongo.delete_many(ArchitectureA1.Mongo, "sales", %{})

    # 50 autores
    authors = for i <- 1..50 do
      name = "Author #{i}"
      {:ok, res} = Mongo.insert_one(ArchitectureA1.Mongo, "authors", %{name: name})
      Map.put(%{name: name}, :id, res.inserted_id)
    end

    # 300 libros
    books = for i <- 1..300 do
      author = Enum.random(authors)
      title = "Book #{i}"
      summary = "Summary for #{title}"
      date_of_publication = ~D[2015-01-01] |> Date.add(:rand.uniform(365*10)) # random within 10 years
      {:ok, res} = Mongo.insert_one(ArchitectureA1.Mongo, "books", %{
        title: title,
        summary: summary,
        date_of_publication: date_of_publication,
        author_id: author.id
      })
      Map.put(%{title: title, author_id: author.id}, :id, res.inserted_id)
    end

    # Reviews
    for book <- books do
      n_reviews = :rand.uniform(10) # 1..10 reviews
      for _ <- 1..n_reviews do
        score = :rand.uniform(5) # 1..5
        text = "Review #{:rand.uniform(1000)}"
        Mongo.insert_one(ArchitectureA1.Mongo, "reviews", %{
          book_id: book.id,
          score: score,
          text: text,
          upvotes: :rand.uniform(10) - 1
        })
      end
    end

    # Sales: al menos 5 años por libro
    current_year = Date.utc_today().year
    for book <- books do
      for y <- (current_year-4)..current_year do
        sales_count = :rand.uniform(1000)
        Mongo.insert_one(ArchitectureA1.Mongo, "sales", %{
          book_id: book.id,
          year: y,
          sales: sales_count
        })
      end
    end

    conn
    |> put_flash(:info, "Seed ejecutado correctamente: 50 autores, 300 libros, reviews y ventas generadas")
    |> redirect(to: "/")
  end
end
