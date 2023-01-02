defmodule GenexRemote.Metrics.EventMetrics do
  use PromEx.Plugin

  @login_prefix [:auth, :login]

  # @logout_prefix [:auth, :logout]
  # @registration_prefix [:auth, :registration]
  # @auth_api_challenge_prefix [:auth, :api_login_challenge]
  # @sync_prefix [:sync, :passwords]

  @audit_prefix [:audit, :event]

  @impl true
  def event_metrics(_opts) do
    [
      auth_metrics(),
      audit_metrics()
    ]
  end

  defp auth_metrics() do
    Event.build(
      :auth,
      [
        counter(
          @login_prefix ++ [:success],
          event_name: @login_prefix ++ [:success],
          measurement: :total,
          description: "Login Success Totals",
          tags: [:email, :account_id]
        ),
        counter(
          @login_prefix ++ [:fail],
          event_name: @login_prefix ++ [:fail],
          measurement: :total,
          description: "Login Failure Totals",
          tags: [:email]
        )
      ]
    )
  end

  defp audit_metrics() do
    Event.build(
      :audit,
      [
        counter(
          @audit_prefix,
          event_name: @audit_prefix,
          measurment: :total,
          description: "Latest event for an email",
          tags: [:email, :event]
        )
      ]
    )
  end
end
