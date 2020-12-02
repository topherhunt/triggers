defmodule Triggers.Data.Trigger do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Triggers.{Data, Repo}
  alias Triggers.Data.{TriggerInstance, User}
  alias Triggers.Helpers, as: H

  schema "triggers" do
    belongs_to :user, User
    has_many :trigger_instances, TriggerInstance
    field :title, :string
    field :why, :string
    field :details, :string
    field :first_due_date, :date
    field :due_time, :time
    field :repeat_in, :integer
    field :repeat_in_unit, :string
    field :last_nagged_at, :utc_datetime
    timestamps()
  end

  def changeset(struct, params, :admin) do
    struct
    |> cast(params, [:user_id, :title, :why, :details, :first_due_date, :due_time, :repeat_in, :repeat_in_unit, :last_nagged_at])
    |> validate_required([:user_id, :title, :why, :first_due_date, :due_time])
    |> validate_inclusion(:repeat_in_unit, ["day", "month"])
    |> validate_repeat_in_fields()
  end

  def changeset(struct, params, :owner) do
    struct
    |> cast(params, [:title, :why, :details, :first_due_date, :due_time, :repeat_in, :repeat_in_unit])
    |> changeset(%{}, :admin) # now do the standard validations & data prep steps
  end

  defp validate_repeat_in_fields(changeset) do
    repeat_in_enabled = !!get_field(changeset, :repeat_in)
    repeat_in_unit_present = !!get_field(changeset, :repeat_in_unit)
    if repeat_in_enabled != repeat_in_unit_present do
      add_error(changeset, :repeat_in, "isn't valid")
    else
      changeset
    end
  end

  #
  # Helpers
  #

  def next_instance(%__MODULE__{} = trigger) do
    Enum.find(trigger.trigger_instances, & &1.status == nil)
  end

  # Used in sorting the upcoming triggers list.
  def next_instance_timestamp(%__MODULE__{} = trigger) do
    if i = next_instance(trigger), do: DateTime.to_unix(i.due_at), else: nil
  end

  # Clears and repopulates the next/active/unresolved instance (if any) of this trigger.
  # A trigger should always have 1+ instances, and a repeating trigger should always have
  # one unresolved instance.
  def refresh_active_instance!(%__MODULE__{} = trigger) do
    # Delete all active/unresolved instances (if any; this will often be a no-op)
    TriggerInstance.filter(trigger: trigger, resolved: false) |> Repo.delete_all()

    last_resolved =
      TriggerInstance.filter(trigger: trigger, resolved: true)
      |> order_by(desc: :due_at)
      |> Repo.first()

    cond do
      last_resolved == nil ->
        # This trigger has no instances yet. Add the first one.
        date = trigger.first_due_date |> H.floor_date(H.today())
        add_new_instance(trigger, date, trigger.due_time)

      trigger.repeat_in != nil ->
        # This trigger is recurring, so we need to add the next-due instance.
        date =
          last_resolved.due_at
          |> H.to_date()
          |> add_repeat_interval(trigger)
          |> H.floor_date(H.today())
        add_new_instance(trigger, date, trigger.due_time)

      true ->
        nil
    end
  end

  def add_repeat_interval(date, %__MODULE__{} = trigger) do
    case trigger.repeat_in_unit do
      "day" -> date |> Timex.shift(days: trigger.repeat_in)
      "month" -> date |> Timex.shift(months: trigger.repeat_in)
    end
  end

  def add_new_instance(%__MODULE__{} = trigger, %Date{} = date, %Time{} = time) do
    date = H.beginning_of_day(date)
    time = Timex.Duration.from_time(time)
    due_at = Timex.add(date, time)
    Data.insert_trigger_instance!(%{trigger_id: trigger.id, due_at: due_at})
  end

  #
  # Filters
  #

  # Apply filters as a keyword list, eg. User.filter(id: 3, email: "blah") |> Repo.all()
  def filter(orig_query \\ __MODULE__, filters) when is_list(filters) do
    Enum.reduce(filters, orig_query, fn {k, v}, query -> filter(query, k, v) end)
  end

  def filter(query, :id, id), do: where(query, [t], t.id == ^id)

  def filter(query, :user, user), do: where(query, [t], t.user_id == ^user.id)

  def filter(query, :user_id, user_id), do: where(query, [t], t.user_id == ^user_id)

  def filter(query, :can_nag, true) do
    cutoff = H.now() |> Timex.shift(minutes: -15)
    where(query, [t], is_nil(t.last_nagged_at) or t.last_nagged_at <= ^cutoff)
  end

  # A trigger is considered active (either due now, or due in the future) if it has any
  # instance that hasn't been resolved yet.
  def filter(query, :active, true) do
    where(query, [t], fragment("EXISTS (SELECT * FROM trigger_instances i WHERE i.trigger_id = ? AND i.status IS NULL)", t.id))
  end

  def filter(query, :due, true) do
    where(query, [t], fragment("EXISTS (SELECT * FROM trigger_instances i WHERE i.trigger_id = ? AND i.status IS NULL AND i.due_at <= ?)", t.id, ^H.now()))
  end
end
