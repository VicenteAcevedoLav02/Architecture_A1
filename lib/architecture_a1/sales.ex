defmodule ArchitectureA1.Sales do
  alias Mongo

  def get_all_sales() do
    Mongo.find(ArchitectureA1.Mongo, "sales", %{})
    |> Enum.map(fn doc ->
      id = BSON.ObjectId.encode!(doc["_id"])
      Map.put(doc, :id, id)
      |> Map.delete("_id")
    end)
  end

  def get_sale_by_id(id) do
    case BSON.ObjectId.decode(id) do
      {:ok, obj_id} ->
        case Mongo.find_one(ArchitectureA1.Mongo, "sales", %{"_id" => obj_id}) do
          nil -> nil
          doc -> Map.put(doc, :id, BSON.ObjectId.encode!(doc["_id"]))
        end

      :error ->
        nil
    end
  end

  def create_sale(attrs) do
    {:ok, result} = Mongo.insert_one(ArchitectureA1.Mongo, "sales", attrs)
    {:ok, result}
  rescue
    e -> {:error, e}
  end

  def update_sale(id, attrs) do
    filter = %{"_id" => BSON.ObjectId.decode!(id)}
    update = %{"$set" => attrs}

    case Mongo.update_one(ArchitectureA1.Mongo, "sales", filter, update) do
      {:ok, %Mongo.UpdateResult{matched_count: 1}} ->
        {:ok, "Sale updated successfully"}

      {:ok, %Mongo.UpdateResult{matched_count: 0}} ->
        {:error, "No sale found with that ID"}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, e}
  end

  def delete_sale(id) do
    filter = %{"_id" => BSON.ObjectId.decode!(id)}

    case Mongo.delete_one(ArchitectureA1.Mongo, "sales", filter) do
      {:ok, %Mongo.DeleteResult{deleted_count: 1}} ->
        {:ok, "Sale deleted successfully"}

      {:ok, %Mongo.DeleteResult{deleted_count: 0}} ->
        {:error, "No sale found with that ID"}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, e}
  end

  def get_sale!(sale_id_hex) when is_binary(sale_id_hex) do
    oid = BSON.ObjectId.decode!(sale_id_hex)
    Mongo.find_one(ArchitectureA1.Mongo, "sales", %{_id: oid}) ||
      raise "Sale not found"
  end

  def get_sales_by_book(book_id) do
    Mongo.find(ArchitectureA1.Mongo, "sales", %{"book_id" => book_id})
    |> Enum.map(fn doc ->
      id = BSON.ObjectId.encode!(doc["_id"])
      Map.put(doc, :id, id)
      |> Map.delete("_id")
    end)
  end
end
