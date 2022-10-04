defmodule GenexRemote.Auth.Account do
  use Ecto.Schema

  import Argon2
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field(:email, :string)
    field(:public_key, :string)
    field(:validated, :utc_datetime)

    field(:encrypted_challenge, :string)
    field(:challenge_expires, :utc_datetime)
    field(:challenge_hash, :string)
    field(:challenge, :string, virtual: true)

    field(:login_token, :string)

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
    |> hash_login_token()
  end

  def token_changeset(account, attrs) do
    account
    |> changeset(attrs)
    |> cast(attrs, [:login_token])
    |> hash_login_token()
  end

  @spec generate_login_token() :: String.t()
  def generate_login_token, do: :crypto.strong_rand_bytes(40) |> Base.url_encode64()

  defp validate_challenge(changeset, account) do
    if changeset.valid? do
      challenge = get_change(changeset, :challenge)
      challenge_hash = get_field(changeset, :challenge_hash)

      if verify_pass(challenge, challenge_hash) do
        changeset
        |> put_change(:encrypted_challenge, "")
        |> put_change(:validated, DateTime.truncate(DateTime.utc_now(), :second))
        |> put_change(:challenge_expires, nil)
      else
        add_error(changeset, :challenge, "challenge is incorrect")
      end
    else
      changeset
    end
  end

  defp hash_login_token(%{valid?: false} = changeset), do: changeset

  defp hash_login_token(%{changes: %{login_token: nil}} = changeset) do
    put_change(changeset, :login_token, nil)
  end

  defp hash_login_token(%{changes: %{login_token: token}} = changeset) do
    put_change(changeset, :login_token, hash_pwd_salt(token))
  end

  defp hash_login_token(%{valid?: true} = cset), do: put_change(cset, :login_token, nil)

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

      case GPG.encrypt(email, dice.phrase) do
        {:ok, encrypted} ->
          changeset
          |> put_change(:encrypted_challenge, encrypted)
          |> change(add_hash(dice.phrase, hash_key: :challenge_hash))
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
