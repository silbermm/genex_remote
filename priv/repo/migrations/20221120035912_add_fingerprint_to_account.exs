defmodule GenexRemote.Repo.Migrations.AddFingerprintToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :fingerprint, :string
    end
  end
end
