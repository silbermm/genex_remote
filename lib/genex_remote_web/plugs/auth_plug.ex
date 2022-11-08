defmodule GenexRemoteWeb.Plugs.AuthPlug do
  import Plug.Conn
  alias GenexRemote.Auth

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    auth_token = get_session(conn, :auth_token)

    if auth_token do
      account =
        cond do
          assigned = conn.assigns[:account] ->
            assigned

          true ->
            # get account id from token
            case GenexRemoteWeb.Tokens.verify_auth_token(auth_token) do
              {:ok, account_id} ->
                Auth.get_account(account_id)

              {:error, _} ->
                Logger.error("INVALID")
                nil
            end
        end

      put_current_account(conn, account)
    else
      conn
    end
  end

  defp put_current_account(conn, nil), do: conn

  defp put_current_account(conn, account) do
    token = GenexRemoteWeb.Tokens.sign_auth_token(account.id)

    conn
    |> assign(:account, account)
    |> put_session(:auth_token, token)
  end
end
