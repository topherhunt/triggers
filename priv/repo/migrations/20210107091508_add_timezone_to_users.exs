defmodule Triggers.Repo.Migrations.AddTimezoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :timezone, :text, default: "US/Eastern"
    end
  end
end
