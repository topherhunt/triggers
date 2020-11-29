defmodule Triggers.Data.TriggerInstance do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Triggers.Data

  schema "trigger_instances" do
    belongs_to :trigger, Triggers.Data.Trigger
    field :date, :date
    field :status, :text
    timestamps()
  end

  def changeset(struct, params, :admin) do
    struct
    |> cast(params, [:trigger_id, :date, :status])
    |> validate_required([:trigger_id, :date])
    |> validate_inclusion(:status, ["done", "wont_do", nil])
  end

  # def changeset(struct, params, :owner) do
  #   struct
  #   |> cast(params, [])
  #   |> changeset(%{}, :admin) # now do the standard validations & data prep steps
  # end

  #
  # Filters
  #

  # Apply filters as a keyword list, eg. User.filter(id: 3, email: "blah") |> Repo.all()
  def filter(orig_query \\ __MODULE__, filters) when is_list(filters) do
    Enum.reduce(filters, orig_query, fn {k, v}, query -> filter(query, k, v) end)
  end

  def filter(query, :trigger_id, id), do: where(query, [t], t.trigger_id == ^id)
end
