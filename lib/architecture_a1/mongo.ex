defmodule ArchitectureA1.Mongo do
  def start_link do
    Mongo.start_link(url: "mongodb://localhost:27017/architecture_a1_dev")
  end
end
