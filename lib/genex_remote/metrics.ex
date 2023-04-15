defmodule GenexRemote.Metrics do
  @moduledoc """
  Emits telemetry events
  """

  @doc """
  Emits a login event and an audit event
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
end
