defmodule GenexRemote.Auth do
  @moduledoc """
  All things authentication/authorization
  """

  import Argon2
  import Ecto.Query

  alias GenexRemote.Auth.Account
  alias GenexRemote.Repo

  require Logger

  @spec new_blank_account() :: Ecto.Changeset.t()
  def new_blank_account(), do: Account.changeset(%Account{}, %{})

  @spec create_account(map()) ::
          {:ok, Account.t(), Ecto.Changeset.t()} | {:error, Ecto.Changeset.t()}
  def create_account(changes) do
    changeset =
      %Account{}
      |> Account.changeset(changes)
      |> Account.challenge_creation_changeset()

    case Repo.insert(changeset) do
      {:ok, account} ->
        # return the account and a challenge changeset
        challenge_changeset = Account.challenge_changeset(account, %{})
        {:ok, account, challenge_changeset}

      err ->
        err
    end
  end

  @spec get_account(String.t()) :: Account.t()
  def get_account(account_id) do
    Repo.get(Account, account_id)
  end

  @spec submit_challenge(Account.t(), map()) :: {:ok, Account.t()} | {:error, Changeset.t()}
  def submit_challenge(account, params) do
    challenge_changeset = Account.challenge_changeset(account, params)
    Repo.update(challenge_changeset)
  end

  @spec send_magic_link(String.t()) :: :ok
  def send_magic_link(email) do
    DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {GenexRemote.DynamicSupervisors, self()}},
      {GenexRemote.AuthMailer, email}
    )

    :ok
  end

  defdelegate generate_login_token, to: Account

  @spec authenticate_by_email_token(String.t(), String.t()) ::
          {:ok, Account.t()} | {:error, :unauthorized}
  def authenticate_by_email_token(email, token) do
    email
    |> get_verified_account_by_email()
    |> case do
      nil ->
        no_user_verify()
        {:error, :unauthorized}

      %Account{login_token: nil} ->
        no_user_verify()
        {:error, :unauthorized}

      account ->
        if verify_pass(token, account.login_token) do
          Logger.info("login token verified!")
          update_login_token(account, nil)
        else
          Logger.error("unable to verify login token")
          {:error, :unauthorized}
        end
    end
  end

  @spec get_verified_account_by_email(String.t()) :: Account.t() | nil
  def get_verified_account_by_email(email) do
    query =
      from(a in Account,
        where: a.email == ^email,
        where: not is_nil(a.validated)
      )

    Repo.one(query)
  end

  @spec update_login_token(Account.t(), nil | String.t()) ::
          {:ok, Account.t()} | {:error, Changeset.t()}
  def update_login_token(%Account{} = account, token) do
    account
    |> Account.token_changeset(%{login_token: token})
    |> Repo.update()
  end
end
