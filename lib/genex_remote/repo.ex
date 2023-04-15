defmodule GenexRemote.Repo do
  use Ecto.Repo,
    otp_app: :genex_remote,
    adapter: Ecto.Adapters.SQLite3
end
