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

user = Factory.insert_user(email: "hunt.topher@gmail.com")

raise "TODO"

IO.puts "Done! You can now log in as UN hunt.topher@gmail.com PW password"
