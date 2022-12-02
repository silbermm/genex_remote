defmodule GenexRemoteWeb.ProfileLive.Index do
  use GenexRemoteWeb, :live_view

  alias GenexRemote.PubSub

  @page_title "Profile"

  @default_assigns [
    page_title: @page_title
  ]

  @impl true
  def mount(_, _, socket) do
    if connected?(socket) do
      # pubsub listen for logs coming in 
      socket.assigns.account.id
      |> PubSub.account_logs()
      |> PubSub.subscribe()
    end

    logs = GenexRemote.Auditor.get_audit_logs_for(socket.assigns.account.id)
    {:ok, assign(socket, @default_assigns ++ [logs: logs])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-white shadow sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <h3 class="text-lg font-medium leading-6 text-gray-900">Public Key Information</h3>
        <p class="mt-1 max-w-2xl text-sm text-gray-500">
          Details about the public key that was uploaded.
        </p>
      </div>
      <div class="border-t border-gray-200">
        <dl>
          <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">Account ID</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"><%= @account.id %></dd>
          </div>
          <div class="bg-white-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">Email</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"><%= @account.email %></dd>
          </div>
          <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">Fingerprint</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              <%= format_fingerprint(@account.fingerprint) %>
            </dd>
          </div>
        </dl>
      </div>
    </div>
    <div class="mt-4">
      <div class="bg-white shadow sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg font-medium leading-6 text-gray-900">Latest Activity</h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Details of the your latest activity
          </p>
        </div>
        <div class="border-t border-gray-200">
          <div class="bg-gray-50 px-4 py-5 sm:px-6">
            <GenexRemoteWeb.Components.Feeds.activity for={@logs} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(%{log_added: log}, socket) do
    updated_logs = [log | socket.assigns.logs]
    {:noreply, assign(socket, logs: updated_logs)}
  end

  defp format_fingerprint(fingerprint) do
    fingerprint
  end
end
