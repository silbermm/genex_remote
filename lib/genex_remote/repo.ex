defmodule GenexRemote.Repo do
  use Ecto.Repo,
    otp_app: :genex_remote,
    adapter: Ecto.Adapters.SQLite3

  alias GenexRemote.Metrics
  alias GenexRemote.PrimarySyncWorker

  require Logger

  defmodule Error do
    defexception [:message]
  end

  @doc """
  Find the Primary node which is the only node that can write to the DB
  and sends the write request to it.
  """
  def primary_write(changeset_struct, opts \\ [], function) do
    case PrimarySyncWorker.get_primary_node() do
      {:ok, p_node} ->
        if node() == p_node do
          Metrics.emit_primary_write_success(_is_remote? = false)
          apply(__MODULE__, function, [changeset_struct, opts])
        else
          Logger.info("Not the primary node: #{node()} != #{p_node}")

          case :rpc.call(p_node, __MODULE__, function, [
                 changeset_struct,
                 opts
               ]) do
            {:badrpc, reason} ->
              Metrics.emit_primary_write_failed(_is_remote? = true)
              raise(Error, "Unable to remote write SQL - #{inspect(reason)}")

            resp ->
              Metrics.emit_primary_write_success(_is_remote? = true)
              resp
          end
        end

      _ ->
        Logger.error("unable to find a primary node, defaulting to local node to write sql")
        Metrics.emit_primary_write_success(_is_remote? = false)
        apply(__MODULE__, function, [changeset_struct, opts])
    end
  end
end
