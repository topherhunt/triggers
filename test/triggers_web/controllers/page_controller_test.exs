defmodule TriggersWeb.PageControllerTest do
  use TriggersWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "That's the wonderful thing about Triggers"
  end
end
