defmodule GenexRemote.Audits.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %{}

  @audit_actions [
    :api_login_challenge_created,
    :api_login_challenge_failed,
    :api_logged_in,
    :logged_in,
    :failed_log_in,
    :logged_out,
    :registered,
    :verified_account,
    :synced_passwords,
    :failed_syncing_passwords
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "auditor" do
    field(:metadata, :map)
    field(:action, Ecto.Enum, values: @audit_actions)

    belongs_to(:account, GenexRemote.Auth.Account)

    timestamps()
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:account_id, :action, :metadata])
    |> validate_required([:action])
    |> assoc_constraint(:account)
  end
end
