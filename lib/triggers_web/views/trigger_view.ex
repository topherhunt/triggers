defmodule TriggersWeb.TriggerView do
  use TriggersWeb, :view

  def due_now?(instance) do
    H.datetime_lte?(instance.due_at, DateTime.utc_now())
  end

  def due_by_today?(instance) do
    H.date_lte?(H.to_date(instance.due_at), Date.utc_today())
  end

  def too_many_new_triggers?(triggers) do
    Enum.count(triggers, & H.date_gte?(H.to_date(&1.inserted_at), Date.utc_today())) >= 1
  end
end
