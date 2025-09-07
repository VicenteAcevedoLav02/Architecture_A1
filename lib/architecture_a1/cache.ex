defmodule ArchitectureA1.Cache do
  @moduledoc """
  API pública para el caché de la aplicación.
  Delega las llamadas a la implementación configurada en config.exs.
  """

  # Lee la configuración para saber qué módulo usar
  defp impl() do
    Application.get_env(:architecture_a1, :cache_module)
  end

  ###
  # DELEGADORES
  # Simplemente reenvían la llamada al módulo correcto (@impl)
  ###

  def get(key), do: impl().get(key)

  def put(key, value, opts \\ []), do: impl().put(key, value, opts)

  def delete(key), do: impl().delete(key)
end
