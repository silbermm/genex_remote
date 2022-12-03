defmodule GenexRemoteWeb.ProfileLive.Index do
  use GenexRemoteWeb, :live_view

  alias GenexRemote.PubSub
  alias GenexRemoteWeb.Components.Feeds
  alias GenexRemoteWeb.Components.Navigation

  @page_title "Profile"

  @default_assigns [
    page_title: @page_title
  ]

  @impl true
  def mount(_, _, socket), do: {:ok, assign(socket, @default_assigns)}

  @impl true
  def handle_params(_params, _url, socket) do
    case socket.assigns.live_action do
      :logs ->
        socket.assigns.account.id
        |> PubSub.account_logs()
        |> PubSub.subscribe()

        logs = GenexRemote.Auditor.get_audit_logs_for(socket.assigns.account.id)

        {:noreply, assign(socket, logs: logs)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("navigate", %{"path" => path}, socket) do
    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Navigation.sub_header title="Profile">
      <:sublink
        :let={data}
        path={Routes.profile_index_path(@socket, :index)}
        content="Public Key"
        selected={@live_action == :index}
      >
        <Navigation.sub_nav_patch_link path={data.path} active={data.active} content={data.content} />
      </:sublink>
      <:sublink
        :let={data}
        content="Logs"
        selected={@live_action == :logs}
        path={Routes.profile_index_path(@socket, :logs)}
      >
        <Navigation.sub_nav_patch_link path={data.path} active={data.active} content={data.content} />
      </:sublink>
    </Navigation.sub_header>

    <%= if @live_action == :index do %>
      <.index_view account={@account} />
    <% end %>

    <%= if @live_action == :logs do %>
      <.logs_view logs={@logs} />
    <% end %>
    """
  end

  @impl true
  def handle_info(%{log_added: log}, socket) do
    updated_logs = [log | socket.assigns.logs]
    {:noreply, assign(socket, logs: updated_logs)}
  end

  defp index_view(assigns) do
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
    """
  end

  def logs_view(assigns) do
    ~H"""
    <div class="bg-white shadow sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <h3 class="text-lg font-medium leading-6 text-gray-900">Latest Activity</h3>
        <p class="mt-1 max-w-2xl text-sm text-gray-500">
          Details of the your latest activity
        </p>
      </div>
      <div class="border-t border-gray-200">
        <div class="bg-gray-50 px-4 py-5 sm:px-6">
          <Feeds.activity for={@logs}>
            <:item :let={log}>
              <Feeds.activity_item
                activity={log.action}
                timestamp={log.inserted_at}
                icon={:user}
                icon_color="bg-blue-500"
                last={is_last?(@logs, log)}
              />
            </:item>
          </Feeds.activity>
        </div>
      </div>
    </div>
    """
  end

  defp format_fingerprint(fingerprint) do
    fingerprint
    |> String.to_charlist()
    |> Enum.chunk_every(2)
    |> Enum.map(&String.Chars.List.to_string/1)
    |> Enum.join(" : ")
  end

  defp is_last?(logs, current) do
    Enum.count(logs) == current.index + 1
  end
end
