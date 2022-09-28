defmodule GenexRemote.Auth do
  @moduledoc """
  All things authentication/authorization
  """

  alias GenexRemote.Auth.Account
  alias GenexRemote.Repo

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

  def submit_challenge(account, params) do
    challenge_changeset = Account.challenge_changeset(account, params)
    Repo.update(challenge_changeset)
  end
end
