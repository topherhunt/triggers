defmodule Triggers.Nagger do
  import Ecto.Query
  alias Triggers.Repo
  alias Triggers.Data.{Trigger, User}
  require Logger

  def send_nags do
    users = User |> Repo.all() |> Enum.filter(& !asleep?(&1))
    log :info, "send_nags starting for #{length(users)} users."

    for user <- users do
      triggers =
        Trigger.filter(user: user, due: true, can_nag: true)
        |> preload(:trigger_instances)
        |> Repo.all()
        |> Enum.sort_by(& Trigger.next_instance_timestamp(&1))

      if length(triggers) > 0 do
        Triggers.Emails.nag(user, triggers) |> Triggers.Mailer.send()
      end
    end
  end

  def asleep?(_user) do
    hour = DateTime.utc_now().hour
    hour >= 23 || hour <= 8
  end

  defp log(level, msg), do: Logger.log(level, "Triggers.Nagger: #{msg}")
end
