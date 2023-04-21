defmodule GenexRemote.PrimarySyncWorker do
  @moduledoc """
  Polls the filesystem for the .primary file. If found, sets the state
  in this process to the the current node name and propogates to all
  the other nodes in the cluster.

  This way, each node has an up-to-date reference of the current DB primary
  node.
  """
  alias GenexRemote.Metrics
  alias Telemetry.Metrics
  use GenServer

  require Logger

  @polling_time 1000

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    Logger.debug("initializing #{__MODULE__}")
    state = find_primary()
    {:ok, state, {:continue, :schedule_polling}}
  end

  def get_primary_node, do: GenServer.call(__MODULE__, :get_primary)

  @impl true
  def handle_continue(:schedule_polling, state) do
    Logger.debug("scheduling #{__MODULE__}")
    Process.send_after(self(), :poll, @polling_time)
    {:noreply, state}
  end

  @impl true
  def handle_info(:poll, current_primary) do
    state =
      if is_primary?() do
        # If i'm the primary, tell the other nodes
        _ = :rpc.sbcast(Node.list(), __MODULE__, {:set_primary, node()})
        node()
      else
        # is my currently suspected primary still connected to me?
        if current_primary in Node.list(), do: current_primary, else: find_primary()
      end

    Process.send_after(self(), :poll, @polling_time)
    {:noreply, state}
  end

  @impl true
  def handle_info({:set_primary, primary}, old_primary) do
    _ = GenexRemote.Metrics.emit_primary_changed(old_primary, primary, node())
    Logger.debug("setting primary to #{primary}")
    {:noreply, primary}
  end

  @impl true
  def handle_call(:get_primary, _from, primary), do: {:reply, primary, primary}

  defp find_primary do
    if is_primary?() do
      node()
    else
      do_find_primary(Node.list())
    end
  end

  defp is_primary? do
    db_file = Application.get_env(:genex_remote, GenexRemote.Repo)[:database]

    db_file
    |> Path.dirname()
    |> Path.join(".primary")
    |> File.exists?()
  end

  defp do_find_primary([]) do
    # there are 0 other nodes, I must be primary
    node()
  end

  defp do_find_primary([first_node | _]) do
    case :rpc.call(first_node, __MODULE__, :get_primary_node, []) do
      {:badrpc, _reason} -> raise "Unable to find primary node"
      primary -> primary
    end
  end
end
