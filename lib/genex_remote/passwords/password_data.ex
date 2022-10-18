defmodule GenexRemote.Passwords.PasswordData do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "password_data" do
    field :data, :string
    field :account_id, :binary_id
    field :shared_with, :binary_id

    timestamps()
  end

  @doc false
  def changeset(password_data, attrs) do
    password_data
    |> cast(attrs, [:data])
    |> validate_required([:data])
  end
end
