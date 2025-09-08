defmodule ArchitectureA1.Cache do
  @moduledoc """
  API pública para el caché de la aplicación.
  Delega las llamadas a la implementación configurada en config.exs.
  """

  require Logger

  # Lee la configuración para saber qué módulo usar
  defp impl() do
    Application.get_env(:architecture_a1, :cache_module)
  end

  ###
  # DELEGADORES
  # Simplemente reenvían la llamada al módulo correcto (@impl)
  ###

  # def get(key), do: impl().get(key)

  # def put(key, value, opts \\ []), do: impl().put(key, value, opts)

  # def delete(key), do: impl().delete(key)

  # def flush(), do: impl().flush()

  def get(key) do
    try do
      impl().get(key)
    rescue
      error ->
        Logger.warning("Cache get failed, returning nil: #{inspect(error)}")
        nil
    end
  end

  def put(key, value, opts \\ []) do
    try do
      impl().put(key, value, opts)
    rescue
      error ->
        Logger.warning("Cache put failed, ignoring: #{inspect(error)}")
        :ok
    end
  end

  def delete(key) do
    try do
      impl().delete(key)
    rescue
      error ->
        Logger.warning("Cache delete failed, ignoring: #{inspect(error)}")
        :ok
    end
  end

  def flush() do
    try do
      impl().flush()
    rescue
      error ->
        Logger.warning("Cache flush failed, ignoring: #{inspect(error)}")
        :ok
    end
  end


end
