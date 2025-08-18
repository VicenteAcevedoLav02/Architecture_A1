defmodule ArchitectureA1.Mongo do
  def start_link(_opts \\ []) do
    Mongo.start_link(
      url: "mongodb://mongo:27017/architecture_a1",
      name: __MODULE__
    )
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
