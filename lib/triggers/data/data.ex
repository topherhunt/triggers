defmodule Triggers.Data do
  import Ecto.Query
  import Ecto.Changeset
  alias Triggers.Repo
  alias Triggers.Data.{User, Nonce, LoginTry, Trigger, TriggerInstance}
  alias Triggers.Helpers, as: H

  #
  # Users
  #

  def insert_user!(a \\ %User{}, b, c), do: insert_user(a, b, c) |> Repo.unwrap!()
  def insert_user(%User{} = struct \\ %User{}, params, scope) do
    struct |> User.changeset(params, scope) |> Repo.insert()
  end

  def update_user!(a, b, c), do: update_user(a, b, c) |> Repo.unwrap!()
  def update_user(%User{} = struct, params, scope) do
    changeset = User.changeset(struct, params, scope)

    # If the user timezone has changed, we need to refresh all their active instance's
    # due_at so the times reflect this timezone.
    if get_change(changeset, :timezone) do
      Repo.all(Trigger.filter(user: struct))
      |> Enum.each(& Trigger.refresh_active_instance!(&1))
    end

    Repo.update(changeset)
  end

  def delete_user!(user), do: Repo.delete!(user)

  def password_correct?(user_or_nil, password) do
    case Argon2.check_pass(user_or_nil, password) do
      {:ok, _user} -> true
      {:error, _msg} -> false
    end
  end

  #
  # Tokens
  #

  # Phoenix.Token gives us signed, salted, reversible, expirable tokens for free.
  # To protect from replay attacks, we embed a nonce id in each (otherwise stateless)
  # token. The nonce is validated at parsing time. Be sure to explicitly invalidate
  # the token when it's no longer needed!
  #
  # Usage:
  #   # Generate a single-use token:
  #   token = Data.new_token({:reset_password, user_id})
  #   # Later, parse and validate the token:
  #   {:ok, {:reset_password, user_id}} = Data.parse_token(token)
  #   # IMPORTANT: Destroy the token as soon as you no longer need it.
  #   Data.invalidate_token!(token)

  @endpoint TriggersWeb.Endpoint
  @salt "XAnZSi88BVsMtchJVa9"
  @one_day 86400

  def create_token!(data) do
    nonce = insert_nonce!()
    wrapped_data = %{data: data, nonce_id: nonce.id}
    Phoenix.Token.sign(@endpoint, @salt, wrapped_data)
  end

  def parse_token(token) do
    case Phoenix.Token.verify(@endpoint, @salt, token, max_age: @one_day) do
      {:ok, map} ->
        case valid_nonce?(map.nonce_id) do
          true -> {:ok, map.data}
          false -> {:error, "invalid nonce"}
        end

      {:error, msg} -> {:error, msg}
    end
  end

  def invalidate_token!(token) do
    {:ok, map} = Phoenix.Token.verify(@endpoint, @salt, token, max_age: :infinity)
    delete_nonce!(map.nonce_id)
    :ok
  end

  #
  # Nonces
  #

  def insert_nonce! do
    Nonce.admin_changeset(%Nonce{}, %{}) |> Repo.insert!()
  end

  def valid_nonce?(id) do
    Repo.get(Nonce, id) != nil
  end

  def delete_nonce!(id) do
    Repo.get!(Nonce, id) |> Repo.delete!()
  end

  #
  # Login tries
  #

  def insert_login_try!(email) do
    LoginTry.admin_changeset(%LoginTry{}, %{email: email}) |> Repo.insert!()
  end

  def count_recent_login_tries(email) do
    email = String.downcase(email)
    time = H.now() |> Timex.shift(minutes: -15)
    LoginTry |> where([t], t.email == ^email and t.inserted_at >= ^time) |> Repo.count()
  end

  def clear_login_tries(email) do
    email = String.downcase(email)
    LoginTry |> where([t], t.email == ^email) |> Repo.delete_all()
  end

  #
  # Triggers
  #

  def insert_trigger!(a, b, c), do: insert_trigger(a, b, c) |> Repo.unwrap!()
  def insert_trigger(struct, params, context) do
    struct
    |> Trigger.changeset(params, context)
    |> Repo.insert()
    |> case do
      {:ok, trigger} ->
        Trigger.refresh_active_instance!(trigger)
        {:ok, trigger}
      other -> other
    end
  end

  def update_trigger!(a, b, c), do: update_trigger(a, b, c) |> Repo.unwrap!()
  def update_trigger(trigger, params, context) do
    trigger
    |> Trigger.changeset(params, context)
    |> Repo.update()
    |> case do
      {:ok, trigger} ->
        Trigger.refresh_active_instance!(trigger)
        {:ok, trigger}
      other -> other
    end
  end

  #
  # TriggerInstances
  #

  def insert_trigger_instance!(params) do
    %TriggerInstance{}
    |> TriggerInstance.changeset(params, :admin)
    |> Repo.insert!()
  end

  def update_trigger_instance!(instance, params) do
    instance
    |> TriggerInstance.changeset(params, :admin)
    |> Repo.update!()
  end

end
