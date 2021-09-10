defmodule Triggers.Repo.Migrations.AddOnHoldToTriggers do
  use Ecto.Migration

  def change do
    alter table(:triggers) do
      add :on_hold, :boolean, default: false, null: false
    end
  end
end
