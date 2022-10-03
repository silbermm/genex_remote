defmodule GenexRemoteWeb.ProfileLive.Index do
  use GenexRemoteWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>
        Welcome <%= @account.email %>
      </h1>
    </div>
    """
  end
end
