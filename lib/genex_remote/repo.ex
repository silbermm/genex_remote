defmodule GenexRemote.Repo do
  use Ecto.Repo,
    otp_app: :genex_remote,
    adapter: Ecto.Adapters.SQLite3

  alias GenexRemote.Metrics
  alias GenexRemote.PrimarySyncWorker

  defmodule Error do
    defexception [:message]
  end

  @doc """

  """
  def primary_write(changeset_struct, opts \\ [], function) do
    if node() == PrimarySyncWorker.get_primary_node() do
      Metrics.emit_primary_write_success(_is_remote? = false)
      apply(__MODULE__, function, [changeset_struct, opts])
    else
      case :rpc.call(PrimarySyncWorker.get_primary_node(), __MODULE__, function, [
             changeset_struct,
             opts
           ]) do
        {:badrpc, reason} -> 
          Metrics.emit_primary_write_failed(_is_remote? = true)
          raise(Error, "Unable to remote write SQL - #{reason}")
        resp ->
          Metrics.emit_primary_write_success(_is_remote? = true)
          resp
      end
    end
  end
end
