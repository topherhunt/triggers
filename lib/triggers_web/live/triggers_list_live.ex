# A simple test LiveView, mounted at the router.
# NOTE: I'm not in love with this router-mounting stuff.
# I might stick with controller-mounted liveviews.
defmodule TriggersWeb.TriggersListLive do
  use TriggersWeb, :live_view

  def render(assigns) do
    TriggersWeb.TriggerView.render("index.html", assigns)
  end

  def mount(_params, session, socket) do
    log :info, "Mounted with session: #{inspect(session)}"
    user = Repo.get!(User, session["user_id"])
    trigger_id = session["selected_trigger_id"]

    socket
    |> assign(
      user: user,
      list: "upcoming",
      modal: (if trigger_id, do: "show", else: nil),
      selected_trigger_id: trigger_id)
    |> load_triggers()
    |> ok()
  end

  def handle_event("inc", _value, socket) do
    socket
    |> assign(count: socket.assigns.count + 1)
    |> noreply()
  end

  def handle_event("dec", _value, socket) do
    socket
    |> assign(count: socket.assigns.count - 1)
    |> noreply()
  end

  #
  # Internal helpers
  #

  defp load_triggers(socket) do
    user = socket.assigns.user
    list = socket.assigns.list

    case list do
      "upcoming" ->

      "history" ->
    end

    triggers =
      Trigger.filter(user_id: socket.assigns.user.id)
      |> preload(:trigger_instances)
      |> Repo.all()

    socket |> assign(triggers: triggers)
  end

  defp ok(socket), do: {:ok, socket}
  defp noreply(socket), do: {:noreply, socket}
end
