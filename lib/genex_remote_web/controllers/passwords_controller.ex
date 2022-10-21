defmodule GenexRemoteWeb.PasswordsController do
  use GenexRemoteWeb, :controller

  alias GenexRemote.Passwords

  def list(conn, _params) do
    account = conn.assigns.account

    latest = GenexRemote.Passwords.latest(account.id)

    conn
    |> put_status(200)
    |> json(%{passwords: latest.data})
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
