defmodule :"Elixir.GenexRemote.Repo.Migrations.Add challengeHash to account" do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :challenge_hash, :text
    end
  end
end
