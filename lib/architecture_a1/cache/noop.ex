defmodule ArchitectureA1.Cache.Noop do
  @moduledoc """
  Cache vacío para cuando Redis no está disponible.
  """

  def get(_key), do: nil
  def put(_key, value, _opts \\ []), do: value
  def delete(_key), do: :ok
  def flush(), do: :ok
end
