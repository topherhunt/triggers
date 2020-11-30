defmodule TriggersWeb.MiscHelpers do
  import TriggersWeb.Gettext

  def required do
    Phoenix.HTML.raw " <span class='text-danger u-tooltip-target'>*<div class='u-tooltip'>#{gettext("Required")}</div></span>"
  end

  def if_path(conn, substring, result) do
    if String.contains?(conn.request_path, substring), do: result
  end
end
