defmodule :"Elixir.GenexRemote.Repo.Migrations.Add loginToken to account" do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :login_token, :string
    end
  end
end
