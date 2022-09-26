defmodule GenexRemote.Repo.Migrations.AddValidatedFieldToAccount do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      add :validated, :utc_datetime
    end
  end

  def down do
    alter table(:accounts) do
      remove :validated
    end
  end
end
