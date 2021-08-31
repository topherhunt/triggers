# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Triggers.Repo.insert!(%Triggers.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Triggers.Factory
alias Triggers.Repo
alias Triggers.Data.{User, Trigger, TriggerInstance}

Repo.delete_all(TriggerInstance)
Repo.delete_all(Trigger)
Repo.delete_all(User)

user = insert_user(email: "hunt.topher@gmail.com", timezone: "Europe/Amsterdam")
_t1 = insert_trigger(user: user, title: "A daily trigger", first_due_date: ~D[2021-08-15], repeat_in: 1, repeat_in_unit: "day")
_t2 = insert_trigger(user: user, title: "Due every 8 days", first_due_date: ~D[2021-08-08], repeat_in: 8, repeat_in_unit: "day")
_t3 = insert_trigger(user: user, title: "Due every 2 weeks", first_due_date: ~D[2021-04-10], repeat_in: 2, repeat_in_unit: "week")

Repo.all(Trigger) |> Enum.each(& Trigger.refresh_active_instance!(&1))

IO.puts "Done! You can now log in as UN hunt.topher@gmail.com PW password"
