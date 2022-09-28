defmodule GenexRemote.Auth.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field(:email, :string)
    field(:public_key, :string)
    field(:validated, :utc_datetime)

    field(:encrypted_challenge, :string)
    field(:challenge_expires, :utc_datetime)

    field(:challenge, :string, virtual: true)

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:email, :public_key])
    |> validate_required([:email, :public_key])
    |> validate_format(:email, ~r/@/, message: "must be a valid email")
    |> unique_constraint(:email)
  end

  def challenge_changeset(account, attrs) do
    account
    |> cast(attrs, [:challenge])
    |> validate_required([:challenge])
    |> validate_challenge(account)
  end

  defp validate_challenge(changeset, account) do
    if changeset.valid? do
      IO.inspect("changeset valid so far")
      challenge = get_change(changeset, :challenge)
      IO.inspect(challenge, label: "challenge submitted")

      case GPG.encrypt(account.email, challenge) do
        {:ok, encrypted} ->
          IO.inspect("challenge encrypted")

          IO.inspect(encrypted)
          IO.inspect(account.encrypted_challenge)

          cond do
            encrypted == account.encrypted_challenge ->
              IO.inspect("equal!")

              changeset
              |> put_change(:encrypted_challenge, "")
              |> put_change(:validated, DateTime.truncate(DateTime.utc_now(), :second))
              |> put_change(:challenge_expires, nil)

            true ->
              IO.inspect("not equal")
              add_error(changeset, :challenge, "challenge is incorrect")
          end

        {:error, reason} ->
          IO.inspect(reason)
          add_error(changeset, :challenge, "invalid challenge response")
      end
    else
      changeset
    end
  end

  @doc """
  Import the public key, create a new challenge
  """
  def challenge_creation_changeset(changeset) do
    changeset
    |> import_key()
    |> create_challenge()
  end

  defp import_key(changeset) do
    public_key = get_change(changeset, :public_key)

    case GPG.import_key(public_key) do
      :ok ->
        changeset

      {:error, reason} ->
        add_error(changeset, :public_key, "public key is invalid or mal-formed")
    end
  end

  defp create_challenge(changeset) do
    if changeset.valid? do
      email = get_change(changeset, :email)
      dice = Diceware.generate()

      IO.inspect dice.phrase, label: "PHRASE"
      case GPG.encrypt(email, dice.phrase) do
        {:ok, encrypted} ->
          changeset
          |> put_change(:encrypted_challenge, encrypted)
          |> put_change(
            :challenge_expires,
            DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second)
          )

        {:error, reason} ->
          add_error(changeset, :public_key, "unable to build a challenge")
      end
    end
  end
end
