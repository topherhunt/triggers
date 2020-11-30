defmodule Triggers.Data.TriggerInstance do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Triggers.Data

  schema "trigger_instances" do
    belongs_to :trigger, Triggers.Data.Trigger
    field :due_at, :utc_datetime
    field :resolved_at
    field :status, :text
    timestamps()
  end

  def changeset(struct, params, :admin) do
    struct
    |> cast(params, [:trigger_id, :due_at, :resolved_at, :status])
    |> validate_required([:trigger_id, :due_at])
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

  def filter(query, :user, user) do
    where(query, [i], fragment("EXISTS (SELECT * FROM triggers t WHERE t.id = ? AND t.user_id = ?)", i.trigger_id, ^user.id))
  end

  def filter(query, :trigger, trigger), do: where(query, [i], i.trigger_id == ^trigger.id)

  def filter(query, :trigger_id, id), do: where(query, [i], i.trigger_id == ^id)

  def filter(query, :resolved, false), do: where(query, [i], is_nil(i.status))

  def filter(query, :resolved, true), do: where(query, [i], not is_nil(i.status))

end
