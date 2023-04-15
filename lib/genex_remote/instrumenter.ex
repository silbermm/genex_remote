defmodule GenexRemote.Instrumenter do
  @moduledoc """
  Handle the telemetry events from the system
  """
  alias GenexRemote.Auth.Account
  require Logger

  def setup do
    events = [
      [:auth, :login, :success],
      [:auth, :login, :fail],
      [:auth, :registration, :success],
      [:auth, :registration, :fail],
      [:auth, :api_login_challenge, :generated],
      [:auth, :api_login_challenge, :failed]
    ]

    :telemetry.attach_many(
      "telemetry-intro-instrumenter",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(
        [:auth, :login, :success],
        _extra,
        %{account_id: account_id} = metadata,
        _config
      ) do
    metadata =
      metadata
      |> Map.drop([:email, :account_id])
      |> format_ip_address()

    GenexRemote.Auditor.write_audit_log(account_id, :logged_in, metadata)
  end

  def handle_event([:auth, :login, :fail], _, %{email: email} = metadata, _) do
    # get account by email (if it exists)
    case GenexRemote.Auth.get_account_by_email(email) do
      nil ->
        :noop

      %Account{} = acct ->
        metadata =
          metadata
          |> Map.drop([:email, :account])
          |> format_ip_address()

        GenexRemote.Auditor.write_audit_log(acct.id, :failed_log_in, metadata)
    end
  end

  def handle_event(
        [:auth, :registration, :success],
        %{account: 1},
        %{account: account},
        _config
      ) do
    Logger.info("AUTH | Successfully registered account")
    GenexRemote.Auditor.write_audit_log(account.id, :registered)
  end

  def handle_event(
        [:auth, :registration, :fail],
        %{account: 0},
        %{error: err} = _metadata,
        _config
      ) do
    Logger.error("AUTH | ERROR | Unable to register account: #{inspect(err)}")
  end

  def handle_event(
        [:auth, :api_login_challenge, :generated],
        _,
        %{account: account} = _metadata,
        _config
      ) do
    Logger.info("AUTH | Generated api login challenge")
    GenexRemote.Auditor.write_audit_log(account.id, :api_login_challenge_created)
  end

  def handle_event(
        [:auth, :api_login_challenge, :failed],
        _,
        %{error: err, email: email} = _metadata,
        _config
      ) do
    Logger.error("AUTH | Unable to generate api login challenge: #{inspect(err)}")

    case GenexRemote.Auth.get_account_by_email(email) do
      nil ->
        :noop

      %Account{} = acct ->
        GenexRemote.Auditor.write_audit_log(acct.id, :api_login_challenge_failed)
    end
  end

  defp format_ip_address(%{ip: {first, second, third, fourth}} = map),
    do: Map.put(map, :ip, "#{first}.#{second}.#{third}.#{fourth}")

  defp format_ip_address(%{ip: _} = map), do: Map.drop(map, [:ip])
  defp format_ip_address(map), do: map
end
