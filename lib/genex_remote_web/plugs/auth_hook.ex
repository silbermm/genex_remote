defmodule GenexRemoteWeb.Plugs.AuthHook do
  @moduledoc """
  Ensures the auth_token is in the session
  then `assigns` the current account to all LiveViews attaching this hook.
  """
  import Phoenix.LiveView
  import Phoenix.Component
  alias GenexRemote.Auth
  alias GenexRemoteWeb.Router.Helpers, as: Routes

  def on_mount(:default, _params, %{"auth_token" => auth_token}, socket) do
    case GenexRemoteWeb.Tokens.verify_auth_token(auth_token) do
      {:ok, account_id} ->
        account = Auth.get_account(account_id)

        if account.validated == nil do
          {:halt,
           socket
           |> put_flash(:error, "must be logged in")
           |> redirect(to: Routes.home_index_path(GenexRemoteWeb.Endpoint, :index))}
        else
          {:cont, assign(socket, :account, account)}
        end

      {:error, _reason} ->
        {:halt,
         socket
         |> put_flash(:error, "must be logged in")
         |> redirect(to: Routes.home_index_path(GenexRemoteWeb.Endpoint, :index))}
    end
  end

  def on_mount(:default, _params, _session, socket) do
    {:halt,
     socket
     |> put_flash(:error, "must be logged in")
     |> redirect(to: Routes.home_index_path(GenexRemoteWeb.Endpoint, :index))}
  end

  def on_mount(:maybe_load, _params, %{"auth_token" => auth_token}, socket) do
    case GenexRemoteWeb.Tokens.verify_auth_token(auth_token) do
      {:ok, account_id} ->
        account = Auth.get_account(account_id)

        if account.validated == nil do
          {:halt,
           socket
           |> put_flash(:error, "must be logged in")
           |> redirect(to: Routes.home_index_path(GenexRemoteWeb.Endpoint, :index))}
        else
          {:cont, assign(socket, account: account, logged_in: true)}
        end

      {:error, _reason} ->
        {:cont, assign(socket, account: nil, logged_in: false)}
    end
  end

  def on_mount(:maybe_load, _params, _session, socket) do
    {:cont, assign(socket, account: nil, logged_in: false)}
  end
end
