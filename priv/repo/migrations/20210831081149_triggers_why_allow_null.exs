defmodule Triggers.Repo.Migrations.TriggersWhyAllowNull do
  use Ecto.Migration

  def change do
    alter table(:triggers) do
      modify :why, :text, null: true
    end
  end
end
