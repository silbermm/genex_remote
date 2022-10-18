defmodule GenexRemote.Passwords do
  @moduledoc """
  Handles saving password data
  """

  alias GenexRemote.Repo
  alias GenexRemote.Passwords.PasswordData

  import Ecto.Query

  @spec latest(String.t()) :: [PasswordData.t()]
  def latest(account_id) do
    query =
      from(p in PasswordData,
        where: p.account_id == ^account_id,
        order_by: [desc: :inserted_at],
        limit: 1
      )

    Repo.one(query)
  end

  @spec save(String.t(), binary()) :: {:ok, PasswordData.t()} | {:error, Ecto.Changeset.t()}
  def save(account_id, passwords) do
    changeset =
      PasswordData.changeset(%PasswordData{}, %{account_id: account_id, data: passwords})

    Repo.insert(changeset)
  end
end
