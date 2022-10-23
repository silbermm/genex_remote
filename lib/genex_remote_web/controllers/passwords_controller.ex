defmodule GenexRemoteWeb.PasswordsController do
  use GenexRemoteWeb, :controller

  alias GenexRemote.Passwords
  require Logger

  def list(conn, _params) do
    account = conn.assigns.account

    data =
      case GenexRemote.Passwords.latest(account.id) do
        %{data: password_data} ->
          password_data

        d ->
          Logger.debug("password data not found in #{inspect(d)}")
          ""
      end

    conn
    |> put_status(200)
    |> json(%{passwords: data})
  end

  def save(conn, %{"passwords" => passwords}) do
    account = conn.assigns.account
    # build a changeset for saving the passwords
    case Passwords.save(account.id, passwords) do
      {:ok, _} ->
        conn
        |> put_status(201)
        |> json(%{})

      {:error, _} ->
        conn
        |> put_status(400)
        |> json(%{error: "unable to save passwords"})
    end
  end
end
