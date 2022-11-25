defmodule GenexRemote.Settings do
  @moduledoc """
  Global Application Settings
  """

  alias GenexRemote.Repo
  alias GenexRemote.Settings.Setting
  import Ecto.Query

  def get_gmail_tokens() do
    "application_settings"
    |> where([s], s.key == "mailer_tokens")
    |> select([s], s.value)
    |> Repo.one()
    |> case do
      "" -> %{}
      nil -> %{}
      data -> Jason.decode!(data)
    end
  end

  def update_gmail_tokens(tokens) do
    "application_settings"
    |> where([s], s.key == "mailer_tokens")
    |> select([s], %Setting{id: s.id, key: s.key})
    |> Repo.one()
    |> Setting.changeset(tokens)
    |> Repo.update()
  end
end
