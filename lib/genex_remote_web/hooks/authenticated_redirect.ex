defmodule GenexRemoteWeb.Hooks.AuthenticatedRedirect do
  @moduledoc """
  If the user is logged in already, redirect to the profile page 
  """
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    if Map.has_key?(socket.assigns, :logged_in) && socket.assigns.logged_in do
      {:halt, socket |> redirect(to: "/profile")}
    else
      {:cont, socket}
    end
  end
end
