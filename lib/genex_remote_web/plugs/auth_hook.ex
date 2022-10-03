defmodule GenexRemoteWeb.Plugs.AuthHook do
  @moduledoc """
  Ensures the account_id is in the session
  then `assigns` the current user to all LiveViews attaching this hook.
  """
  import Phoenix.LiveView
  import Phoenix.Component
  alias GenexRemote.Auth
  alias GenexRemoteWeb.Router.Helpers, as: Routes

  def on_mount(:default, _params, %{"account_id" => account_id}, socket) do
    account = Auth.get_account(account_id)

    if account.validated == nil do
      {:halt,
       socket
       |> put_flash(:error, "must be logged in")
       |> redirect(to: Routes.home_index_path(GenexRemoteWeb.Endpoint, :index))}
    else
      {:cont, assign(socket, :account, account)}
    end
  end

  def on_mount(:default, _params, _session, socket) do
    {:halt,
     socket
     |> put_flash(:error, "must be logged in")
     |> redirect(to: Routes.home_index_path(GenexRemoteWeb.Endpoint, :index))}
  end

  def on_mount(:maybe_load, _params, %{"account_id" => account_id}, socket) do
    account = Auth.get_account(account_id)

    if account.validated == nil do
      {:halt,
       socket
       |> put_flash(:error, "must be logged in")
       |> redirect(to: Routes.home_index_path(GenexRemoteWeb.Endpoint, :index))}
    else
      {:cont, assign(socket, account: account, logged_in: true)}
    end
  end

  def on_mount(:maybe_load, _params, _session, socket) do
    {:cont, assign(socket, account: nil, logged_in: false)}
  end
end
