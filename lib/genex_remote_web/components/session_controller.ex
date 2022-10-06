defmodule GenexRemoteWeb.SessionController do
  use GenexRemoteWeb, :controller

  alias GenexRemote.Auth

  def create_from_token(conn, %{"email" => email, "token" => token}) do
    case Auth.authenticate_by_email_token(email, token) do
      {:ok, account} ->
        token = GenexRemoteWeb.Tokens.sign_auth_token(account.id)

        conn
        |> put_session(:auth_token, token)
        |> put_flash(:info, "Welcome back")
        |> configure_session(renew: true)
        |> redirect(to: Routes.home_index_path(conn, :index))

      _ ->
        conn
        |> put_flash(:error, "Invalid login")
        |> redirect(to: Routes.home_index_path(conn, :index))
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: Routes.home_index_path(conn, :index))
  end
end
