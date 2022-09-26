defmodule GenexRemote.Auth.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :email, :string
    field :public_key, :string
    field :validated, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:email, :public_key])
    |> validate_required([:email, :public_key])
    |> validate_format(:email, ~r/@/, message: "must be a valid email")
    |> unique_constraint(:email)
  end
end
