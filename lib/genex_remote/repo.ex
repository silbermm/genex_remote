defmodule GenexRemote.Repo do
  use Ecto.Repo,
    otp_app: :genex_remote,
    adapter: Ecto.Adapters.SQLite3

  @doc """
  Replicate the query on the the other nodes in the cluster
  """
  def replicate(func) when is_function(func) do
    _ =
      for node <- Node.list() do
        GenServer.cast({GenexRemote.RepoReplication, node}, {:replicate, func})
      end

    :ok
  end

  def replicate({:ok, data_to_replicate} = ret, operation) when operation in [:insert, :update] do
    _ =
      for node <- Node.list() do
        GenServer.cast(
          {GenexRemote.RepoReplication, node},
          {:replicate, data_to_replicate, operation}
        )
      end

    ret
  end

  def replicate({:error, _changeset} = ret, _), do: ret

  def replicate(%Ecto.Changeset{} = changeset, operation) when operation in [:insert, :update] do
    _ =
      for node <- Node.list() do
        GenServer.cast(
          {GenexRemote.RepoReplication, node},
          {:replicate, changeset, operation}
        )
      end

    {:ok, changeset}
  end

  def replicate(schema, :insert) do
    _ =
      for node <- Node.list() do
        GenServer.cast(
          {GenexRemote.RepoReplication, node},
          {:replicate, schema, :insert}
        )
      end

    {:ok, schema}
  end
end
