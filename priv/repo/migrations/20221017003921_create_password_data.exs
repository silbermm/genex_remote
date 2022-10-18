defmodule GenexRemote.Repo.Migrations.CreatePasswordData do
  use Ecto.Migration

  def change do
    create table(:password_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :data, :text
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)
      add :shared_with, references(:accounts, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:password_data, [:account_id])
    create index(:password_data, [:shared_with])
  end
end
