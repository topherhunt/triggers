defmodule TriggersWeb.TriggerView do
  use TriggersWeb, :view
  alias Triggers.Data.Trigger

  def get_latest_resolved_instances(trigger, n) do
    trigger.trigger_instances
    |> Enum.filter(& &1.status != nil)
    |> Enum.sort_by(& -DateTime.to_unix(&1.resolved_at))
    |> Enum.take(n)
  end

  def due_now?(instance) do
    H.datetime_lte?(instance.due_at, DateTime.utc_now())
  end

  def due_on_today?(instance) do
    H.to_date(instance.due_at) == Date.utc_today()
  end

  def due_by_today?(instance) do
    H.date_lte?(H.to_date(instance.due_at), H.today())
  end

  def due_before_today?(instance) do
    H.date_lt?(H.to_date(instance.due_at), H.today())
  end

  def too_many_new_triggers?(triggers) do
    Enum.count(triggers, & H.date_gte?(H.to_date(&1.inserted_at), H.today())) >= 1
  end

  def time_class(instance) do
    cond do
      !due_on_today?(instance) -> "text-muted small"
      due_on_today?(instance) && due_now?(instance) -> "text-danger"
      true -> ""
    end
  end
end
