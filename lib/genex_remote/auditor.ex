defmodule GenexRemote.Auditor do
  @moduledoc """
  Handles writing audit logs to the DB and
  broadcasting to any listening processes
  """
  use GenServer, restart: :transient

  alias Ecto.Changeset
  alias GenexRemote.Audits.AuditLog
  alias GenexRemote.Repo
  alias GenexRemote.PubSub

  import Ecto.Query

  require Logger

  @log_prefix "[Auditor] | "

  ##### Public API

  @doc """
  Get the last n (defaults to 100) audit logs for the specified account
  """
  @spec get_audit_logs_for(String.t(), non_neg_integer()) :: list(AuditLog.t())
  def get_audit_logs_for(account_id, count \\ 100) do
    "auditor"
    |> where([a], a.account_id == ^account_id)
    |> order_by([a], desc: a.inserted_at)
    |> limit([_], ^count)
    |> select([a], %{action: a.action, inserted_at: a.inserted_at, metadata: a.metadata})
    |> Repo.all()
  end

  def write_audit_log(account_id, action, metadata \\ %{}) do
    params = %{account_id: account_id, action: action, metadata: metadata}

    DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {GenexRemote.DynamicSupervisors, self()}},
      {GenexRemote.Auditor, params}
    )

    :ok
  end

  ##### PROCESS DEFINITION AND LOGIC
  def start_link(params), do: GenServer.start_link(__MODULE__, params)

  @impl true
  def init(params) do
    # build the changeset here
    Logger.info([
      @log_prefix,
      "Initializing auditor"
    ])

    changeset = AuditLog.changeset(%AuditLog{}, params)
    {:ok, %{changeset: changeset}, {:continue, :commit}}
  end

  @impl true
  def handle_continue(:commit, %{changeset: %Changeset{valid?: true} = changeset} = state) do
    case Repo.insert(changeset) do
      {:ok, log} ->
        Logger.info([
          @log_prefix,
          "Successfully wrote audit log"
        ])

        Repo.replicate(Repo.preload(log, [:account]), :insert)

        log.account_id
        |> PubSub.account_logs()
        |> GenexRemote.PubSub.broadcast(%{log_added: log})

        {:stop, :normal, state}

      {:error, _changeset} ->
        Logger.error([
          @log_prefix,
          "Unabled to write audit log"
        ])

        {:stop, :normal, state}
    end
  end

  @impl true
  def handle_continue(:commit, _invalid_changeset = state) do
    Logger.error([
      @log_prefix,
      "Unabled to write audit log - changeset is invalid"
    ])

    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.info([
      @log_prefix,
      "cleanup and exit"
    ])

    {:ok, state}
  end
end
