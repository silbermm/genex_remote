defmodule GenexRemote.Settings.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  @setting_keys [
    :mailer_tokens
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "application_settings" do
    field(:key, Ecto.Enum, values: @setting_keys)
    field :value, :map

    timestamps()
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
  end
end
