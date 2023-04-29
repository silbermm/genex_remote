defmodule GenexRemote.PrimarySyncWorker do
  @moduledoc """
  Polls the filesystem for the .primary file. If found, sets the hostname
  state in this process to the the current name in the .primary file and 
  propogates to all the other nodes in the cluster.

  Each node listens for the hostname and checks it's own hostname to see
  if it's primary.

  If a node does NOT have a .primary file, it's most likely the primary.
  """

  use GenServer

  require Logger

  @polling_time 5000

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    Logger.info("initializing #{__MODULE__}")
    state = %{primary_node: nil, primary_hostname: nil, hostname: get_current_hostname()}
    {:ok, state, {:continue, :find_primary}}
  end

  ##############
  # PUBLIC API #
  ##############

  def get_primary_node, do: GenServer.call(__MODULE__, :get_primary_node)
  def get_primary_hostname, do: GenServer.call(__MODULE__, :get_primary_hostname)
  def matches_hostname?(hostname), do: GenServer.call(__MODULE__, {:matches_hostname?, hostname})

  #############
  # CALLBACKS #
  #############

  @impl true
  def handle_continue(:find_primary, state) do
    Logger.info("Finding primary")
    {node, hostname} = find_primary()
    Process.send_after(self(), :poll, @polling_time)
    Logger.info("Setting primary in #{node()} to #{node}")
    {:noreply, %{state | primary_hostname: hostname, primary_node: node}}
  end

  @impl true
  def handle_info(:poll, state) do
    {node, hostname} = find_primary()
    Logger.info("Setting primary in #{node()} to #{node}")
    Process.send_after(self(), :poll, @polling_time)
    {:noreply, %{state | primary_hostname: hostname, primary_node: node}}
  end

  @impl true
  def handle_call(:get_primary_node, _from, %{primary_node: nil} = state),
    do: {:reply, :unknown, state}

  def handle_call(:get_primary_node, _from, %{primary_node: primary_node} = state),
    do: {:reply, {:ok, primary_node}, state}

  def handle_call(:get_primary_hostname, _from, %{primary_hostname: nil} = state),
    do: {:reply, :unknown, state}

  def handle_call(:get_primary_hostname, _from, %{primary_hostname: primary_hostname} = state),
    do: {:reply, {:ok, primary_hostname}, state}

  def handle_call({:matches_hostname?, hostname}, _from, %{hostname: current_hostname} = state)
      when hostname == current_hostname,
      do: {:reply, true, state}

  def handle_call({:matches_hostname?, _hostname}, _from, state),
    do: {:reply, false, state}

  ####################
  # HELPER FUNCTIONS #
  ####################
  defp get_current_hostname do
    {name, _} = System.cmd("hostname", [])
    String.trim(name)
  end

  defp find_primary do
    if is_primary_present?() do
      prim_host = do_get_primary_hostname()
      primary_node = do_find_primary_by_hostname(Node.list(), prim_host)
      {primary_node, prim_host}
    else
      # ask the other nodes if they know who is primary
      node = do_find_primary_without_hostname(Node.list())
      host = do_find_primary_hostname(Node.list())
      {node, host}
    end
  end

  defp is_primary_present?, do: File.exists?(primary_path())

  defp primary_path do
    db_file = Application.get_env(:genex_remote, GenexRemote.Repo)[:database]

    db_file
    |> Path.dirname()
    |> Path.join(".primary")
  end

  defp do_get_primary_hostname do
    primary_path()
    |> File.read()
    |> case do
      {:ok, hostname} ->
        Logger.info(".primary file contents - #{inspect(hostname)}")
        String.trim(hostname)

      err ->
        Logger.error(inspect(err))
        raise ".primary file not readable"
    end
  end

  defp do_find_primary_by_hostname([], _), do: node()

  defp do_find_primary_by_hostname(nodes, primary_host_name) do
    # ask the other nodes if they match this recorded hostname
    for node <- nodes, reduce: node() do
      acc ->
        case :rpc.call(node, __MODULE__, :matches_hostname?, [primary_host_name]) do
          true -> node
          false -> acc
          _ -> acc
        end
    end
  end

  defp do_find_primary_without_hostname([]), do: node()

  defp do_find_primary_without_hostname(nodes) do
    for node <- nodes, reduce: node() do
      acc ->
        case :rpc.call(node, __MODULE__, :get_primary_node, []) do
          {:ok, n} -> n
          :unknown -> acc
          _ -> acc
        end
    end
  end

  defp do_find_primary_hostname([]), do: get_current_hostname()

  defp do_find_primary_hostname(nodes) do
    for node <- nodes, reduce: get_current_hostname() do
      acc ->
        case :rpc.call(node, __MODULE__, :get_primary_hostname, []) do
          {:ok, n} -> n
          :unknown -> acc
          _ -> acc
        end
    end
  end
end
