defmodule TriggersWeb.TriggerView do
  use TriggersWeb, :view

  def due_now?(instance) do
    H.datetime_lte?(instance.due_at, DateTime.utc_now())
  end

  def due_by_today?(instance) do
    H.date_lte?(H.to_date(instance.due_at), Date.utc_today())
  end
end
