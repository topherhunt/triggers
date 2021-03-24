# Initially I planned to implement all this in LiveView. But when I tried to do so, it
# felt conceptually jumbled. So I'm starting with the traditional CRUD approach and might
# shoehorn this all into a liveview once the core logic is worked out.
#
defmodule TriggersWeb.TriggerController do
  use TriggersWeb, :controller
  alias Triggers.Data
  alias Triggers.Data.{Trigger, TriggerInstance}

  plug :must_be_logged_in

  # The "main" view. Lists all triggers that are due now or due in the future,
  # ordered by due date/time ascending.
  def upcoming(conn, _params) do
    live_render(conn, TriggersWeb.UpcomingTriggersLive,
      session: %{"current_user_id" => conn.assigns.current_user.id})
  end

  # Lists all instances of triggers I've completed in the past, in descending order.
  def history(conn, _params) do
    instances =
      TriggerInstance.filter(user: conn.assigns.current_user, resolved: true)
      |> order_by(desc: :resolved_at)
      |> preload(:trigger)
      |> Repo.all()

    render(conn, "history.html", instances: instances)
  end

  def show(conn, %{"id" => id}) do
    trigger = load_trigger(conn, id)
    next_instance = TriggerInstance.filter(trigger: trigger, resolved: false) |> Repo.one()
    past_instances =
      TriggerInstance.filter(trigger: trigger, resolved: true)
      |> order_by(desc: :resolved_at)
      |> Repo.all()
    render(conn, "show.html", trigger: trigger, past_instances: past_instances, next_instance: next_instance)
  end

  def new(conn, _params) do
    changeset = Trigger.changeset(%Trigger{}, %{first_due_date: H.today(), due_time: H.now()}, :owner)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"trigger" => trigger_params}) do
    user = conn.assigns.current_user
    case Data.insert_trigger(%Trigger{user_id: user.id}, trigger_params, :owner) do
      {:ok, _trigger} ->
        conn
        |> put_flash(:info, "Trigger saved.")
        |> redirect(to: Routes.trigger_path(conn, :upcoming))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    trigger = load_trigger(conn, id)
    changeset = Trigger.changeset(trigger, %{}, :owner)
    render(conn, "edit.html", trigger: trigger, changeset: changeset)
  end

  def update(conn, %{"id" => id, "trigger" => trigger_params}) do
    trigger = load_trigger(conn, id)
    case Data.update_trigger(trigger, trigger_params, :owner) do
      {:ok, trigger} ->
        conn
        |> put_flash(:info, "Trigger saved.")
        |> redirect(to: return_to_path(conn, trigger))
      {:error, changeset} ->
        render(conn, "edit.html", trigger: trigger, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    trigger = load_trigger(conn, id)
    TriggerInstance.filter(trigger: trigger) |> Repo.delete_all()
    Repo.delete!(trigger)

    conn
    |> put_flash(:info, "Trigger deleted.")
    |> redirect(to: Routes.trigger_path(conn, :upcoming))
  end

  def resolve(conn, %{"instance_id" => instance_id, "status" => status}) do
    user = conn.assigns.current_user
    instance = TriggerInstance.filter(id: instance_id, user: user) |> Repo.one!()
    trigger = Repo.get!(Trigger, instance.trigger_id)
    Data.update_trigger_instance!(instance, %{status: status})
    Trigger.refresh_active_instance!(trigger)

    conn
    |> put_flash(:info, (if status == "done", do: happy(), else: sad()))
    |> redirect(to: return_to_path(conn, trigger))
  end

  #
  # Internal
  #

  defp load_trigger(conn, id) do
    Trigger.filter(user: conn.assigns.current_user, id: id) |> Repo.one!()
  end

  defp return_to_path(conn, trigger) do
    case conn.params["return_to"] do
      "upcoming" -> Routes.trigger_path(conn, :upcoming)
      "history" -> Routes.trigger_path(conn, :history)
      _ -> Routes.trigger_path(conn, :show, trigger)
    end
  end

  defp happy, do: H.random_emojis(~w(🎉 🎊 👯‍♀️ 🥳 💃 😎 😽 🤓 🐮 🐴 🐱 🐶), 3)

  defp sad, do: H.random_emojis(~w(😕 🤥 😐 🤕), 1)
end
