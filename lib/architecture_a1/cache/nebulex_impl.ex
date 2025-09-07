defmodule ArchitectureA1.Cache.NebulexImpl do
  @moduledoc """
  Implementación real del caché usando Nebulex y Redis.
  """

  use Nebulex.Cache,
    otp_app: :architecture_a1,
    adapter: NebulexRedisAdapter
end
