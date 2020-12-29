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

  def assert_same(list1, list2) do
    assert H.sort(Enum.map(list1, & &1.id)) == H.sort(Enum.map(list2, & &1.id))
  end
end
