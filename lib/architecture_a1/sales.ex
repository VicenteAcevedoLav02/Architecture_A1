defmodule ArchitectureA1.Sales do
  alias Mongo

  alias ArchitectureA1.Cache
  alias ArchitectureA1.Books

  # --- Claves de Caché ---
  @all_sales_key "sales:all"
  defp sale_cache_key(id), do: "sale:#{id}"
  defp sales_for_book_key(book_id), do: "sales:for_book:#{book_id}"
  defp top_by_year_key(year, n), do: "sales:top_by_year:#{year}:#{n}"

  def get_all_sales() do
    case Cache.get(@all_sales_key) do
      sales when is_list(sales) -> sales
      nil ->
        sales_from_db =
          Mongo.find(ArchitectureA1.Mongo, "sales", %{})
          |> Enum.map(fn doc ->
            id = BSON.ObjectId.encode!(doc["_id"])
            Map.put(doc, :id, id) |> Map.delete("_id")
          end)
        Cache.put(@all_sales_key, sales_from_db, ttl: :timer.hours(1))
        sales_from_db
    end
  end

  def get_sale_by_id(id) do
    cache_key = sale_cache_key(id)
    case Cache.get(cache_key) do
      sale when is_map(sale) ->
        sale
      nil ->
        case BSON.ObjectId.decode(id) do
          {:ok, obj_id} ->
            case Mongo.find_one(ArchitectureA1.Mongo, "sales", %{"_id" => obj_id}) do
              nil ->
                nil
              doc ->
                sale_from_db = Map.put(doc, :id, BSON.ObjectId.encode!(doc["_id"]))
                Cache.put(cache_key, sale_from_db, ttl: :timer.hours(1))
                sale_from_db
            end
          :error ->
            nil
        end
    end
  end

  def create_sale(attrs) do
    case Mongo.insert_one(ArchitectureA1.Mongo, "sales", attrs) do
      {:ok, result} ->
        book_id = attrs["book_id"]
        year = attrs["year"]

        Cache.delete(@all_sales_key)
        Cache.delete(sales_for_book_key(book_id))
        Cache.delete(top_by_year_key(year, 5))
        Cache.delete(top_by_year_key(year, 10))

        Books.recalculate_number_of_sales(book_id)

        {:ok, result}
      {:error, e} -> {:error, e}
    end
  end

  def update_sale(id, attrs) do
    with %{"book_id" => book_id, "year" => year} <- get_sale_by_id(id) do
      filter = %{"_id" => BSON.ObjectId.decode!(id)}
      update = %{"$set" => attrs}

      case Mongo.update_one(ArchitectureA1.Mongo, "sales", filter, update) do
        {:ok, %Mongo.UpdateResult{matched_count: 1}} ->
          Cache.delete(@all_sales_key)
          Cache.delete(sale_cache_key(id))
          Cache.delete(sales_for_book_key(book_id))
          Cache.delete(top_by_year_key(year, 5))
          Cache.delete(top_by_year_key(year, 10))
          Books.recalculate_number_of_sales(book_id)

          {:ok, "Sale updated successfully"}

        {:ok, %Mongo.UpdateResult{matched_count: 0}} ->
          {:error, "No sale found with that ID"}

        {:error, reason} ->
          {:error, reason}
      end
    else
      _ -> {:error, "No sale found with that ID"}
    end
  end

  def delete_sale(id) do
    with %{"book_id" => book_id, "year" => year} <- get_sale_by_id(id) do
      filter = %{"_id" => BSON.ObjectId.decode!(id)}

      case Mongo.delete_one(ArchitectureA1.Mongo, "sales", filter) do
        {:ok, %Mongo.DeleteResult{deleted_count: 1}} ->
          Cache.delete(@all_sales_key)
          Cache.delete(sale_cache_key(id))
          Cache.delete(sales_for_book_key(book_id))
          Cache.delete(top_by_year_key(year, 5))
          Cache.delete(top_by_year_key(year, 10))
          Books.recalculate_number_of_sales(book_id)

          {:ok, "Sale deleted successfully"}

        {:ok, %Mongo.DeleteResult{deleted_count: 0}} ->
          {:error, "No sale found with that ID"}

        {:error, reason} ->
          {:error, reason}
      end
    else
      _ -> {:error, "No sale found with that ID"}
    end
  end

  def get_sale!(sale_id_hex) when is_binary(sale_id_hex) do
    oid = BSON.ObjectId.decode!(sale_id_hex)
    Mongo.find_one(ArchitectureA1.Mongo, "sales", %{_id: oid}) ||
      raise "Sale not found"
  end

  def get_sales_by_book(book_id) do
    cache_key = sales_for_book_key(book_id)
    case Cache.get(cache_key) do
      sales when is_list(sales) ->
        sales
      nil ->
        sales_from_db =
          Mongo.find(ArchitectureA1.Mongo, "sales", %{"book_id" => book_id})
          |> Enum.map(fn doc ->
            id = BSON.ObjectId.encode!(doc["_id"])
            Map.put(doc, :id, id) |> Map.delete("_id")
          end)

        Cache.put(cache_key, sales_from_db, ttl: :timer.hours(1))
        sales_from_db
    end
  end

  def get_top_n_by_year(year, n) do
    cache_key = top_by_year_key(year, n)
    case Cache.get(cache_key) do
      top_sales when is_list(top_sales) ->
        top_sales
      nil ->
        pipeline = [
          %{"$match" => %{"year" => year}},
          %{"$addFields" => %{"sales_int" => %{"$toInt" => "$sales"}}},
          %{"$group" => %{
              "_id" => "$book_id",
              "total_sales" => %{"$sum" => "$sales_int"}
          }},
          %{"$sort" => %{"total_sales" => -1}},
          %{"$limit" => n}
        ]

        result =
          ArchitectureA1.Mongo
          |> Mongo.aggregate("sales", pipeline, [])
          |> Enum.to_list()
          |> Enum.map(fn doc ->
            %{"book_id" => doc["_id"], "total_sales" => doc["total_sales"]}
          end)

        Cache.put(cache_key, result, ttl: :timer.minutes(30))
        result
    end
  end
end
