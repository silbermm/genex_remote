defmodule GenexRemoteWeb.Plugs.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller
  alias GenexRemoteWeb.Router.Helpers, as: Routes
  alias GenexRemote.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    account_id = get_session(conn, :account_id)

    if account_id do
      account =
        cond do
          assigned = conn.assigns[:account] -> assigned
          true -> Auth.get_account(account_id)
        end

      put_current_account(conn, account)
    else
      conn
    end
  end

  defp put_current_account(conn, account) do
    token = account && Phoenix.Token.sign(GenexRemoteWeb.Endpoint, "account auth", account.id)

    conn
    |> assign(:account, account)
    |> assign(:account_token, token)
    |> put_session(:account_token, token)
  end
end
