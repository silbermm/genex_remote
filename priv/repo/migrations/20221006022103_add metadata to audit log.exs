defmodule :"Elixir.GenexRemote.Repo.Migrations.Add metadata to audit log" do
  use Ecto.Migration

  def change do
    alter table(:auditor) do
      add :metadata, :map
    end
  end
end
