defmodule ArchitectureA1.Cache.Behaviour do
  @callback get(key :: any()) :: any() | nil
  @callback put(key :: any(), value :: any(), opts :: Keyword.t()) :: :ok
  @callback delete(key :: any()) :: :ok
  @callback flush() :: :ok
end
