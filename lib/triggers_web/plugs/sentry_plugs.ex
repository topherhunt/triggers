defmodule TriggersWeb.SentryPlugs do
  import Plug.Conn
  import Phoenix.Controller
  import TriggersWeb.Gettext
  alias Triggers.Helpers, as: H
  alias TriggersWeb.Router.Helpers, as: Routes

  def must_be_logged_in(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      if H.xhr?(conn) do
        conn
        |> put_status(401)
        |> json(%{error: "unauthorized, please log in"})
        |> halt()
      else
        conn
        |> put_flash(:error, gettext("Please log in first."))
        |> redirect(to: Routes.auth_path(conn, :login))
        |> halt()
      end
    end
  end
end
