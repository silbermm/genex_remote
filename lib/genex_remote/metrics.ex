defmodule GenexRemote.Metrics do
  @moduledoc """
  Emits telemetry events
  """

  @doc """
  Emits a login event and an audit event
  """
  def emit_login_event(email, account_id) do
    :telemetry.execute(
      [:auth, :login, :success],
      %{total: 1},
      %{email: email, account_id: account_id, ip: ""}
    )

    :telemetry.execute(
      [:audit, :event],
      %{total: 1},
      %{email: email, event: :login}
    )
  end

  def emit_login_failed(email) do
    :telemetry.execute(
      [:auth, :login, :fail],
      %{total: 1},
      %{email: email, ip: ""}
    )

    :telemetry.execute(
      [:audit, :event],
      %{total: 1},
      %{email: email, event: :login_failed}
    )
  end
end
