defmodule ArchitectureA1.Cache do
  @moduledoc """
  Cache principal de la app usando Nebulex con Redis.
  """

  use Nebulex.Cache,
    otp_app: :architecture_a1,
    adapter: NebulexRedisAdapter
end
