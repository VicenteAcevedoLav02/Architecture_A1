defmodule ArchitectureA1.Cache do
  @moduledoc "Optional cache layer with Redis"

  def put(key, value, ttl \\ 300) do
    case Redix.command(:redix, ["SETEX", key, Integer.to_string(ttl), Jason.encode!(value)]) do
      {:ok, _} -> :ok
      _ -> :noop  # allows the app to run if Redis fails
    end
  end

  def get(key) do
    case Redix.command(:redix, ["GET", key]) do
      {:ok, nil} -> :not_found
      {:ok, json} -> {:ok, Jason.decode!(json)}
      _ -> :not_found
    end
  end

  def delete(key), do: Redix.command(:redix, ["DEL", key])
end
