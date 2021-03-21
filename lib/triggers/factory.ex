defmodule Triggers.Factory do
  alias Triggers.{Data, Repo}
  alias Triggers.Data.{Trigger, TriggerInstance}
  alias Triggers.Helpers, as: H

  def insert_user(params \\ %{}) do
    params = cast(params, [:name, :email, :confirmed_at, :timezone])
    uuid = random_uuid()

    Data.insert_user!(%{
      name: Map.get(params, :name, "User #{}"),
      email: String.downcase(Map.get(params, :email, "user_#{uuid}@example.com")),
      password: "password",
      confirmed_at: Map.get(params, :confirmed_at, DateTime.utc_now()),
      timezone: params[:timezone] || "US/Eastern"
    }, :admin)
  end

  def insert_login_try(params \\ %{}) do
    params = cast(params, [:email])
    Data.insert_login_try!(params[:email])
  end

  # WARNING: Unlike Data.insert_trigger(), this does NOT autopopulate a TriggerInstance.
  # You need to manually insert the trigger instance as a subsequent command.
  def insert_trigger(params \\ %{}) do
    params = cast(params, [:user, :user_id, :title, :first_due_date, :due_time, :repeat_in, :repeat_in_unit, :last_nagged_at])

    attrs = %{
      user_id: params[:user_id] || H.try(params[:user], :id) || insert_user().id,
      title: params[:title] || "Trigger #{random_uuid()}",
      why: "the reason",
      first_due_date: params[:first_due_date] || H.today(),
      due_time: params[:due_time] || ~T[21:00:00],
      repeat_in: params[:repeat_in],
      repeat_in_unit: params[:repeat_in_unit],
      last_nagged_at: params[:last_nagged_at]
    }

    %Trigger{} |> Trigger.changeset(attrs, :admin) |> Repo.insert!()
  end

  def insert_trigger_instance(params \\ %{}) do
    params = cast(params, [:trigger, :trigger_id, :due_at, :resolved_at, :status])

    attrs = %{
      trigger_id: params[:trigger_id] || H.try(params[:trigger], :id) || insert_trigger().id,
      due_at: params[:due_at] || DateTime.utc_now(),
      resolved_at: params[:resolved_at] || nil,
      status: params[:status] || nil
    }

    %TriggerInstance{} |> TriggerInstance.changeset(attrs, :admin) |> Repo.insert!()
  end

  def random_uuid, do: Nanoid.generate(8)

  #
  # Internal
  #

  defp cast(params, allowed_keys) do
    params = Enum.into(params, %{})
    unexpected_key = Map.keys(params) |> Enum.find(& &1 not in allowed_keys)
    if unexpected_key, do: raise "Unexpected key: #{inspect(unexpected_key)}."
    params
  end
end
