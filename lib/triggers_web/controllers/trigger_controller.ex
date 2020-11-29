defmodule TriggersWeb.TriggerController do
  use TriggersWeb, :controller

  plug :require_login

  def index(conn, params) do
    session = %{
      "user_id" => conn.assigns.current_user.id,
      "trigger_id" => params["trigger_id"],
      "action" => params["action"]
    }
    live_render(conn, TriggersWeb.TriggersListLive, session: session)
  end

  def mark_done(conn, %{"trigger_instance_id" => id}) do
    current_user = conn.assigns.current_user
    instance = TriggerInstance.filter(id: id, user: current_user) |> Repo.one!()
    trigger = Repo.get!(Trigger, instance.trigger_id)
    Data.update_trigger_instance!(instance, %{status: "done"})
    Data.populate_next_trigger_instance(trigger)

    raise "TODO"
    # - Implement TriggerInstance filters
    # - Implement Data.populate_next_trigger_instance

    conn
    |> put_flash("Marked as done.")
    |> redirect(to: Routes.triggers_path(conn, :index))
  end

  def mark_wont_do(conn, %{"trigger_instance_id" => id}) do
    raise "TODO"
  end
end
