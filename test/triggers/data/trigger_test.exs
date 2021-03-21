defmodule Triggers.Data.TriggerTest do
  use Triggers.DataCase
  import Factory
  alias Triggers.Data.{Trigger, TriggerInstance}

  test "filters work properly" do

    # user

    Repo.delete_all(Trigger)

    user1 = insert_user()
    user2 = insert_user()
    trigger1 = insert_trigger(user: user1)
    trigger2 = insert_trigger(user: user2)

    ids = Trigger.filter(user: user1) |> Repo.all() |> Enum.map(& &1.id)
    assert trigger1.id in ids
    assert trigger2.id not in ids

    # due_at

    Repo.delete_all(Trigger)

    trigger1 = insert_trigger()
    trigger2 = insert_trigger()
    trigger3 = insert_trigger()

    insert_trigger_instance(trigger: trigger1, due_at: H.in_mins(5))
    insert_trigger_instance(trigger: trigger2, due_at: H.mins_ago(5))
    insert_trigger_instance(trigger: trigger3, due_at: H.mins_ago(5), status: "done")

    ids = Trigger.filter(due: true) |> Repo.all() |> Enum.map(& &1.id)
    assert trigger1.id not in ids
    assert trigger2.id in ids
    assert trigger3.id not in ids

    # can_nag

    Repo.delete_all(Trigger)
    Repo.delete_all(TriggerInstance)

    trigger1 = insert_trigger(last_nagged_at: nil)
    trigger2 = insert_trigger(last_nagged_at: H.mins_ago(9))
    trigger3 = insert_trigger(last_nagged_at: H.mins_ago(11))

    ids = Trigger.filter(can_nag: true) |> Repo.all() |> Enum.map(& &1.id)
    assert trigger1.id in ids
    assert trigger2.id not in ids
    assert trigger3.id in ids
  end

  describe "#refresh_active_instance!" do
    test "works when adding the first instance" do
      user = insert_user(timezone: "America/Los_Angeles")
      trigger = insert_trigger(
        user: user,
        first_due_date: ~D[2021-02-01],
        due_time: ~T[15:00:00]) # 3 PM local time

      Trigger.refresh_active_instance!(trigger)

      # One instance was created, due on first_due_date at 3 PM LA timezone = 23:00 UTC.
      [instance] = Repo.all(TriggerInstance.filter(trigger: trigger))
      assert instance.due_at == ~U[2021-02-01 23:00:00Z]
    end

    test "works when adding a repeat instance" do
      user = insert_user(timezone: "America/Los_Angeles")
      trigger = insert_trigger(
        user: user,
        first_due_date: ~D[2021-02-01],
        due_time: ~T[15:00:00], # 3 PM local time
        repeat_in: 7, repeat_in_unit: "day")
      insert_trigger_instance(trigger: trigger,
        due_at: ~U[2021-02-12 01:00:00Z],
        resolved_at: H.now(),
        status: "wont_do")

      Trigger.refresh_active_instance!(trigger)

      # The next instance's due date is based on the 7-day cycle starting from the first
      # due date, NOT starting from the previous instance's due/resolved dates.
      [instance] = Repo.all(TriggerInstance.filter(trigger: trigger, resolved: false))
      assert instance.due_at == ~U[2021-02-15 23:00:00Z]
    end
  end
end
