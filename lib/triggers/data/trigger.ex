defmodule Triggers.Data.Trigger do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Triggers.Data

  schema "triggers" do
    belongs_to :user, Triggers.Data.User
    field :title, :string
    field :why, :string
    field :details, :string
    field :first_due_date, :date
    field :due_time, :time
    field :repeat_in, :integer
    field :repeat_in_unit, :string
    field :last_nagged_at, :utc_datetime
    timestamps()
  end

  def changeset(struct, params, :admin) do
    struct
    |> cast(params, [:user_id, :title, :why, :details, :first_due_date, :due_time, :repeat_in, :repeat_in_unit, :last_nagged_at])
    |> validate_required([:user_id, :title, :why, :first_due_date, :due_time])
  end

  def changeset(struct, params, :owner) do
    struct
    |> cast(params, [:title, :why, :details, :first_due_date, :due_time, :repeat_in, :repeat_in_unit])
    |> changeset(%{}, :admin) # now do the standard validations & data prep steps
  end

  #
  # Filters
  #

  # Apply filters as a keyword list, eg. User.filter(id: 3, email: "blah") |> Repo.all()
  def filter(orig_query \\ __MODULE__, filters) when is_list(filters) do
    Enum.reduce(filters, orig_query, fn {k, v}, query -> filter(query, k, v) end)
  end

  def filter(query, :user_id, user_id), do: where(query, [t], t.user_id == ^user_id)
end
