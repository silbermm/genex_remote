defmodule GenexRemote.Repo.Migrations.AddEncryptedChallengeAndExpiryToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :challenge_expires, :utc_datetime
      add :encrypted_challenge, :text
    end
  end
end
