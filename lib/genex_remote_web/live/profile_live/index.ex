defmodule GenexRemoteWeb.ProfileLive.Index do
  use GenexRemoteWeb, :live_view

  @page_title "Profile"

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, :page_title, @page_title)}
  end

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
