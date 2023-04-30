defmodule GenexRemote.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    GenexRemote.Instrumenter.setup()

    if System.get_env("ECTO_IPV6") do
      :httpc.set_option(:ipfamily, :inet6fb4)
    end

    :ok = :opentelemetry_cowboy.setup()
    :ok = OpentelemetryPhoenix.setup()
    :ok = OpentelemetryLiveView.setup()

    :ok =
      GenexRemote.Repo.config()
      |> Keyword.fetch!(:telemetry_prefix)
      |> OpentelemetryEcto.setup()

    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      GenexRemote.Repo,
      GenexRemoteWeb.Telemetry,
      GenexRemote.PromEx,
      {Phoenix.PubSub, name: GenexRemote.PubSub},
      GenexRemoteWeb.Endpoint,
      {PartitionSupervisor, child_spec: DynamicSupervisor, name: GenexRemote.DynamicSupervisors},
      {Cluster.Supervisor, [topologies, [name: GenexRemote.ClusterSupervisor]]},
      GenexRemote.PrimarySyncWorker
    ]

    opts = [strategy: :one_for_one, name: GenexRemote.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    GenexRemoteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
