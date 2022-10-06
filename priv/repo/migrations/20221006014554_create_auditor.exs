defmodule GenexRemote.Repo.Migrations.CreateAuditor do
  use Ecto.Migration

  def change do
    create table(:auditor, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :action, :string
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:auditor, [:account_id])
  end
end
