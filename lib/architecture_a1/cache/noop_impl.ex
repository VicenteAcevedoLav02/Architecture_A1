defmodule ArchitectureA1.Cache.NoopImpl do
  @behaviour ArchitectureA1.Cache.Behaviour

  @impl true
  def get(_key), do: nil

  @impl true
  def put(_key, _value, _opts), do: :ok

  @impl true
  def delete(_key), do: :ok
end
