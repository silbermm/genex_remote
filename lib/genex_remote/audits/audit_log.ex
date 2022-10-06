defmodule GenexRemote.Audits.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  @audit_actions [:logged_in, :logged_out, :registered]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "auditor" do
    field :metadata, :map
    field :action, Ecto.Enum, values: @audit_actions

    belongs_to :account, GenexRemote.Auth.Account

    timestamps()
  end

  @doc false
  def changeset(audit_log, attrs) do
    IO.inspect("HERE")

    audit_log
    |> cast(attrs, [:account_id, :action, :metadata])
    |> validate_required([:action])
    |> assoc_constraint(:account)
  end
end
