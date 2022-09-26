defmodule GenexRemoteWeb.HomeLive.Index do
  use GenexRemoteWeb, :live_view

  def mount(_, _, socket) do
    {:ok, assign(socket, :page_title, "Home")}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Welcome</h1>
    </div>
    """
  end
end
