defmodule TriggersWeb.PageControllerTest do
  use TriggersWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Triggers Homepage"
  end
end
