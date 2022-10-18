defmodule GenexRemoteWeb.Plugs.ApiAuthPlug do
  import Plug.Conn
  import Phoenix.Controller
  alias GenexRemoteWeb.Router.Helpers, as: Routes
  alias GenexRemote.Auth

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    auth_header = get_req_header(conn, "authorization")

    case auth_header do
      ["Bearer " <> token] ->
        case GenexRemoteWeb.Tokens.verify_api_auth_token(token) do
          {:ok, account_id} ->
            account = Auth.get_account(account_id)
            put_current_account(conn, account)

          {:error, _} ->
            conn
            |> put_status(401)
            |> halt()
        end

      _ ->
        conn
        |> put_status(401)
        |> halt()
    end
  end

  defp put_current_account(conn, account) do
    token = GenexRemoteWeb.Tokens.sign_api_auth_token(account.id)

    conn
    |> assign(:account, account)
    |> put_resp_header("authorization", token)
  end
end
