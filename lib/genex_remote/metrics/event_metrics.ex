defmodule GenexRemote.Metrics.EventMetrics do
  use PromEx.Plugin

  @login_prefix [:auth, :login]

  # @logout_prefix [:auth, :logout]
  # @registration_prefix [:auth, :registration]
  # @auth_api_challenge_prefix [:auth, :api_login_challenge]
  # @sync_prefix [:sync, :passwords]

  @audit_prefix [:audit, :event]
  @db_primary_prefix [:db, :primary]
  @db_primary_write_prefix [:db, :primary_write]

  @impl true
  def event_metrics(_opts) do
    [
      auth_metrics(),
      db_metrics()
    ]
  end

  defp db_metrics() do
    Event.build(
      :db,
      [
        counter(
          @db_primary_prefix ++ [:changed],
          event_name: @db_primary_prefix ++ [:changed],
          measurment: :total,
          description: "DB Primary Changed Totals",
          tags: [:old_primary_node, :new_primary_node, :reporting_node]
        ),
        counter(
          @db_primary_write_prefix ++ [:succeeded],
          event_name: @db_primary_write_prefix ++ [:succeeded],
          measurment: :total,
          description: "DB Primary Write Success Totals",
          tags: [:remote]
        ),
        counter(
          @db_primary_write_prefix ++ [:failed],
          event_name: @db_primary_write_prefix ++ [:failed],
          measurment: :total,
          description: "DB Primary Write Failure Totals",
          tags: [:remote]
        )
      ]
    )
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
end
