defmodule ArchitectureA1Web.PageController do
  use ArchitectureA1Web, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
