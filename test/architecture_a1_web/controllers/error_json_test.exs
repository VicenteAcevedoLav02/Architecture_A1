defmodule ArchitectureA1Web.ErrorJSONTest do
  use ArchitectureA1Web.ConnCase, async: true

  test "renders 404" do
    assert ArchitectureA1Web.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ArchitectureA1Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
