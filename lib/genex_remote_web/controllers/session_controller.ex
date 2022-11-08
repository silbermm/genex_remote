defmodule GenexRemoteWeb.SessionController do
  use GenexRemoteWeb, :controller

  alias GenexRemote.Auth

  require Logger

  def create_from_token(conn, %{"email" => email, "token" => token}) do
    case Auth.authenticate_by_email_token(email, token) do
      {:ok, account} ->
        token = GenexRemoteWeb.Tokens.sign_auth_token(account.id)
        GenexRemote.Auditor.write_audit_log(account.id, :logged_in)

        conn
        |> put_session(:auth_token, token)
        |> put_flash(:info, "Welcome back")
        |> configure_session(renew: true)
        |> redirect(to: Routes.home_index_path(conn, :index))

      {:error, reason} ->
        Logger.error("#{inspect(reason)}")

        conn
        |> put_flash(:error, "Invalid login")
        |> redirect(to: Routes.home_index_path(conn, :index))
    end
  end

  def api_request_challenge(conn, %{"email" => email}) do
    # find the account for the requested email
    case Auth.generate_api_login_challenge(email) do
      {:ok, challenge} ->
        conn
        |> put_status(200)
        |> json(%{challenge: challenge})

      {:error, _reason} ->
        conn
        |> put_status(500)
        |> json(%{message: "invalid email or public key"})
    end
  end

  def api_submit_challenge_response(conn, %{"email" => email, "challenge_response" => response}) do
    case Auth.validate_challenge_response(email, response) do
      {:ok, account} ->
        token = GenexRemoteWeb.Tokens.sign_api_auth_token(account.id)
        GenexRemote.Auditor.write_audit_log(account.id, :api_logged_in)

        conn
        |> put_status(200)
        |> json(%{token: token})

      {:error, _changeset} ->
        conn
        |> put_status(500)
        |> json(%{message: "invalid challenge response"})
    end
  end

  def logout(conn, _params) do
    account = conn.assigns[:account]

    if account do
      GenexRemote.Auditor.write_audit_log(account.id, :logged_out)
    end

    conn
    |> configure_session(drop: true)
    |> redirect(to: Routes.home_index_path(conn, :index))
  end
end
