defmodule TriggersWeb.UserView do
  use TriggersWeb, :view

  def timezone_options do
    Timex.timezones()
    |> Enum.map(& Timex.timezone(&1, Timex.now()))
    |> Enum.sort_by(& &1.offset_utc)
    |> Enum.map(fn timezone ->
      offset = round(timezone.offset_utc / 3600)
      label = "#{timezone.full_name} (UTC#{if offset >= 0, do: "+"}#{offset})"
      {label, timezone.full_name}
    end)
  end
end
