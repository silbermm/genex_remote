defmodule GenexRemote.Auth do
  @moduledoc """
  All things authentication/authorization
  """

  import Argon2
  import Ecto.Query

  alias GenexRemote.Metrics
  alias GenexRemote.Auth.Account
  alias GenexRemote.Repo
  alias Ecto.Changeset

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

    case Repo.primary_write(changeset, :insert) do
      {:ok, account} ->
        Metrics.emit_registration_success(account)

        # return the account and a challenge changeset
        challenge_changeset = Account.challenge_changeset(account, %{})

        {:ok, account, challenge_changeset}

      {:error, changeset} ->
        Metrics.emit_registration_failed(changes, changeset.errors)
        {:error, changeset}
    end
  end

  def build_challenge_changeset(account_id) do
    now = DateTime.utc_now()

    Account
    |> where([a], a.id == ^account_id)
    |> where([a], is_nil(a.validated))
    |> where([a], a.challenge_expires > ^now)
    |> Repo.one()
    |> case do
      nil ->
        {:error, "Account not valid, or already registered"}

      account ->
        account
        |> Account.changeset(%{})
        |> Account.challenge_creation_changeset()
        |> Repo.primary_write(:update)
        |> case do
          {:ok, updated_account} ->
            {:ok, updated_account, Account.challenge_changeset(updated_account, %{})}

          _ ->
            {:error, "Unable to build a challenge"}
        end
    end
  end

  @spec get_account(String.t()) :: Account.t() | nil
  def get_account(account_id), do: Repo.get(Account, account_id)

  @spec get_account_by_email(String.t()) :: Account.t() | nil
  def get_account_by_email(email), do: Repo.get_by(Account, email: email)

  @spec submit_challenge(Account.t(), map()) :: {:ok, Account.t()} | {:error, Changeset.t()}
  def submit_challenge(account, params) do
    account
    |> Account.challenge_changeset(params)
    |> Repo.primary_write(:update)
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

  def generate_api_login_challenge(email) do
    # find the account for the requested email
    case get_verified_account_by_email(email) do
      nil ->
        no_user_verify()
        {:error, :unauthorized}

      account ->
        account
        |> Account.changeset(%{})
        |> Account.create_challenge()
        |> Repo.primary_write(:update)
        |> case do
          {:ok, account} ->
            Metrics.emit_login_challenge_created(account)
            {:ok, account.encrypted_challenge}

          {:error, changeset} ->
            Metrics.emit_login_challenge_failed(email, changeset.errors)
            {:error, changeset}
        end
    end
  end

  def validate_challenge_response(email, response) do
    case get_verified_account_by_email(email) do
      nil ->
        no_user_verify()
        {:error, :unauthorized}

      account ->
        account
        |> Account.challenge_changeset(%{challenge: response, login_token: nil})
        |> Repo.primary_write(:update)
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
    |> Repo.primary_write(:update)
  end
end
