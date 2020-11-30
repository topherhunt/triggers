defmodule Triggers.Repo.Migrations.CreateTriggers do
  use Ecto.Migration

  def change do
    create table(:triggers) do
      add :user_id, :integer, null: false
      add :title, :text, null: false
      add :why, :text, null: false
      add :details, :text
      add :first_due_date, :date, null: false
      add :due_time, :time, null: false
      add :repeat_in, :integer
      add :repeat_in_unit, :text
      add :last_nagged_at, :utc_datetime
      timestamps()
    end

    create index(:triggers, [:user_id])

    create table(:trigger_instances) do
      add :trigger_id, :integer, null: false
      add :due_at, :utc_datetime, null: false
      add :resolved_at, :utc_datetime
      add :status, :text
      timestamps()
    end

    create index(:trigger_instances, [:trigger_id])
  end
end
