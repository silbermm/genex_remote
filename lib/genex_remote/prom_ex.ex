defmodule GenexRemote.PromEx do
  @moduledoc """

  """
  use PromEx, otp_app: :genex_remote

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      Plugins.PhoenixLiveView,
      Plugins.Ecto,
      GenexRemote.Metrics.EventMetrics
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "curl",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      # PromEx built in Grafana dashboards
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"}
      # {:prom_ex, "phoenix.json"},
      # {:prom_ex, "ecto.json"},
      # {:prom_ex, "oban.json"},
      # {:prom_ex, "phoenix_live_view.json"},
      # {:prom_ex, "absinthe.json"},
      # {:prom_ex, "broadway.json"},

      # Add your dashboard definitions here with the format: {:otp_app, "path_in_priv"}
      # {:genex_remote, "/grafana_dashboards/user_metrics.json"}
    ]
  end
end
