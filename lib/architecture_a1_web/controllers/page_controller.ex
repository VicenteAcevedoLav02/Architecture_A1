defmodule ArchitectureA1Web.PageController do
  use ArchitectureA1Web, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def index(conn, _params) do
    render(conn, :index)
  end
end
