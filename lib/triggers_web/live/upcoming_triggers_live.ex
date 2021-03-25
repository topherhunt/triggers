defmodule TriggersWeb.UpcomingTriggersLive do
  use TriggersWeb, :live_view
  import Ecto.Query
  alias Triggers.{Repo, Data}
  alias Triggers.Data.{User, Trigger, TriggerInstance}
  require Logger

  def render(assigns) do
    TriggersWeb.TriggerView.render("upcoming_live.html", assigns)
  end

  def mount(_params, session, socket) do
    current_user = Repo.get!(User, Map.fetch!(session, "current_user_id"))
    log :info, "mounting. current_user: #{current_user.id}"

    socket
    |> assign(current_user: current_user)
    |> assign(triggers: load_triggers(current_user))
    |> ok()
  end

  def handle_event("resolve", params, socket) do
    user = socket.assigns.current_user
    %{"instance-id" => instance_id, "status" => status} = params
    log :info, "handle_event(resolve, params: #{inspect params}, user: #{user.id})"

    instance = TriggerInstance.filter(id: instance_id, user: user) |> Repo.one!()
    trigger = Repo.get!(Trigger, instance.trigger_id)
    Data.update_trigger_instance!(instance, %{status: status})
    Trigger.refresh_active_instance!(trigger)

    socket
    |> assign(triggers: load_triggers(user))
    |> noreply()
  end

  #
  # Low-level helpers
  #

  def load_triggers(%User{} = user) do
    Trigger.filter(user: user, active: true)
    |> preload(:trigger_instances)
    |> Repo.all()
    |> Enum.sort_by(& Trigger.next_instance_timestamp(&1))
  end

  defp ok(socket), do: {:ok, socket}
  defp noreply(socket), do: {:noreply, socket}
  defp log(level, message), do: Logger.log(level, "UpcomingTriggersLive: #{message}")
end
