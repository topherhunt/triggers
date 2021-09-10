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
    field :due_time, :time # in your local timezone
    field :repeat_in_unit, :string # eg. "day"
    field :repeat_in, :integer     # eg. 3
    field :last_nagged_at, :utc_datetime
    field :on_hold, :boolean
    timestamps()
  end

  def changeset(struct, params, :admin) do
    struct
    |> cast(params, [:user_id, :title, :why, :details, :first_due_date, :due_time, :repeat_in_unit, :repeat_in, :last_nagged_at, :on_hold])
    |> validate_required([:user_id, :title, :first_due_date, :due_time])
    |> validate_inclusion(:repeat_in_unit, ["day", "week", "month"])
    |> validate_repeat_in_fields()
  end

  def changeset(struct, params, :owner) do
    struct
    |> cast(params, [:title, :why, :details, :first_due_date, :due_time, :repeat_in_unit, :repeat_in, :on_hold])
    |> changeset(%{}, :admin) # now do the standard validations & data prep steps
  end

  defp validate_repeat_in_fields(changeset) do
    repeat_in_num_present = !!get_field(changeset, :repeat_in)
    repeat_in_unit_present = !!get_field(changeset, :repeat_in_unit)

    cond do
      repeat_in_num_present && !repeat_in_unit_present ->
        add_error(changeset, :repeat_in_unit, "please select one")

      !repeat_in_num_present && repeat_in_unit_present ->
        add_error(changeset, :repeat_in, "please enter a number")

      true ->
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
  # TODO: Move this to a dedicated service module.
  def refresh_active_instance!(%__MODULE__{} = trigger) do
    # Delete all active/unresolved instances (if any; this will often be a no-op)
    TriggerInstance.filter(trigger: trigger, resolved: false) |> Repo.delete_all()

    last_resolved =
      TriggerInstance.filter(trigger: trigger, resolved: true)
      |> order_by(desc: :due_at)
      |> Repo.first()

    cond do
      last_resolved == nil ->
        # This trigger has no instances yet. Add the first one, on the original due date.
        date = trigger.first_due_date # |> H.floor_date(H.today())
        add_new_instance(trigger, date)

      trigger.repeat_in != nil ->
        # This trigger is recurring, so we need to add the next-due instance.
        date = min_date(
          # Set the due date to whatever time interval covers today...
          trigger.first_due_date
            # |> IO.inspect(label: "first_due_date")
            |> advance_by_repeat_interval(trigger, until_past: H.yesterday())
            # |> IO.inspect(label: "until past yesterday")
            |> add_repeat_interval(trigger, -1),
            # |> IO.inspect(label: "after removing 1 repeat_interval"),
          # ...but it must be later than the last due date.
          trigger.first_due_date
            |> advance_by_repeat_interval(trigger, until_past: H.to_date(last_resolved.due_at))
            # |> IO.inspect(label: "until past last resolved")
        )

        IO.puts "Adding new instance on date: #{date}"
        add_new_instance(trigger, date)

      true ->
        # This trigger already has a resolved instance and does not complete.
        # Don't need to add an active instance.
        nil
    end
  end

  defp min_date(a, b) do
    if H.date_gt?(a, b), do: a, else: b
  end

  # Given a starting date, repeatedly step forward in time by the trigger's repeat interval
  # until the `until_past` date has been passed.
  def advance_by_repeat_interval(date, trigger, [until_past: %Date{} = until_past]) do
    if H.date_gt?(date, until_past) do
      date
    else
      date = add_repeat_interval(date, trigger, 1)
      advance_by_repeat_interval(date, trigger, until_past: until_past)
    end
  end

  def add_repeat_interval(date, %__MODULE__{} = trigger, num) do
    case trigger.repeat_in_unit do
      "day" -> date |> Timex.shift(days: trigger.repeat_in * num)
      "week" -> date |> Timex.shift(weeks: trigger.repeat_in * num)
      "month" -> date |> Timex.shift(months: trigger.repeat_in * num)
    end
  end

  def add_new_instance(%__MODULE__{} = trigger, %Date{} = date) do
    trigger = Repo.preload(trigger, :user)
    # The instance will be due on the given date, at the time specified on the trigger
    # (in the user's timezone).
    due_at =
      Timex.to_datetime(date, trigger.user.timezone)
      |> H.beginning_of_day()
      |> Timex.add(Timex.Duration.from_time(trigger.due_time))
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

  # Exclude triggers that were recently nagged.
  def filter(query, :can_nag, true) do
    cutoff = H.now() |> Timex.shift(minutes: -10)
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

  def filter(query, :on_hold, val), do: where(query, [t], t.on_hold == ^val)
end
