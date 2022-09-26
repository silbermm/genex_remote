defmodule GenexRemote.Auth do
  @moduledoc """
  All things authentication/authorization
  """

  alias GenexRemote.Auth.Account
  alias GenexRemote.Repo

  @spec new_blank_account() :: Ecto.Changeset.t()
  def new_blank_account(), do: Account.changeset(%Account{}, %{})

  @spec create_account(map()) :: {:ok, Account.t()} | {:error, Changeset.t()}
  def create_account(changes) do
    changeset = Account.changeset(%Account{}, changes)
    Repo.insert(changeset)
  end
end
