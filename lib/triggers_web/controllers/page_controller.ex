defmodule TriggersWeb.PageController do
  use TriggersWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
