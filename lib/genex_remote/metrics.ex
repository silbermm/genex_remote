defmodule GenexRemote.Metrics do
  @moduledoc """
  Emits telemetry events
  """

  def emit_login_success(email, account_id) do
    :telemetry.execute(
      [:auth, :login, :success],
      %{total: 1},
      %{email: email, account_id: account_id, ip: ""}
    )
  end

  def emit_login_failed(email) do
    :telemetry.execute(
      [:auth, :login, :fail],
      %{total: 1},
      %{email: email, ip: ""}
    )
  end

  def emit_registration_success(account) do
    # TODO: capture IP address
    :telemetry.execute(
      [:auth, :registration, :success],
      %{account: 1},
      %{account: account}
    )
  end

  def emit_registration_failed(params, error) do
    :telemetry.execute(
      [:auth, :registration, :fail],
      %{account: 0},
      %{error: error, params: params}
    )
  end

  def emit_login_challenge_created(account) do
    :telemetry.execute([:auth, :api_login_challenge, :generated], %{}, %{
      account: account
    })
  end

  def emit_login_challenge_failed(email, error) do
    :telemetry.execute([:auth, :api_login_challenge, :failed], %{}, %{
      email: email,
      error: error
    })
  end

  def emit_primary_changed(old_node, new_primary_node, reporting_node) do
    :telemetry.execute([:db, :primary, :changed], %{total: 1}, %{
      new_primary_node: new_primary_node,
      old_primary_node: old_node,
      reporting_node: reporting_node
    })
  end

  def emit_primary_write_success(is_remote?) do
    :telemetry.execute([:db, :primary_write, :succeeded], %{total: 1}, %{
      remote: is_remote?
    })
  end

  def emit_primary_write_failed(is_remote?) do
    :telemetry.execute([:db, :primary_write, :failed], %{total: 1}, %{
      remote: is_remote?
    })
  end
end
