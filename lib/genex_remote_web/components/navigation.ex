defmodule GenexRemoteWeb.Components.Navigation do
  use Phoenix.Component

  alias GenexRemoteWeb.Router.Helpers, as: Routes
  alias GenexRemoteWeb.Endpoint

  attr :account, GenexRemote.Auth.Account, default: nil

  def header(assigns) do
    ~H"""
    <header class="bg-indigo-600">
      <nav class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8" aria-label="Top">
        <div class="flex w-full items-center justify-between border-b border-indigo-500 py-6 lg:border-none">
          <div class="flex items-center">
            <.link navigate={Routes.home_index_path(Endpoint, :index)}>
              <span class="sr-only">Your Company</span>
              <img class="h-10 w-auto" src={Routes.static_path(Endpoint, "/images/logo.png")} alt="" />
            </.link>
            <div class="ml-10 hidden space-x-8 lg:block">
              <.link
                navigate={Routes.home_index_path(Endpoint, :index)}
                class="text-base font-medium text-white hover:text-indigo-50"
              >
                Home
              </.link>
            </div>
          </div>
          <div class="ml-10 space-x-4">
            <%= if @account do %>
              <.link
                navigate={Routes.profile_index_path(Endpoint, :index)}
                class="inline-block rounded-md border border-transparent bg-indigo-500 py-2 px-4 text-base font-medium text-white hover:bg-opacity-75"
              >
                Profile
              </.link>
              <.link
                navigate={Routes.session_path(Endpoint, :logout)}
                class="inline-block rounded-md border border-transparent bg-white py-2 px-4 text-base font-medium text-indigo-600 hover:bg-indigo-50"
              >
                Logout
              </.link>
            <% else %>
              <.link
                navigate={Routes.auth_register_path(Endpoint, :register)}
                class="inline-block rounded-md border border-transparent bg-indigo-500 py-2 px-4 text-base font-medium text-white hover:bg-opacity-75"
              >
                Register
              </.link>
              <.link
                navigate={Routes.auth_login_path(Endpoint, :login)}
                class="inline-block rounded-md border border-transparent bg-white py-2 px-4 text-base font-medium text-indigo-600 hover:bg-indigo-50"
              >
                Login
              </.link>
            <% end %>
          </div>
        </div>
        <div class="flex flex-wrap justify-center space-x-6 py-4 lg:hidden">
          <%= if @account do %>
            <.link
              navigate={Routes.profile_index_path(Endpoint, :index)}
              class="text-base font-medium text-white hover:text-indigo-50"
            >
              Profile
            </.link>
          <% end %>
        </div>
      </nav>
    </header>
    """
  end

  attr :title, :string, required: true

  slot(:sublink, required: true) do
    attr :content, :string
    attr :selected, :boolean
    attr :path, :string
  end

  def sub_header(assigns) do
    ~H"""
    <div class="relative border-b border-gray-200 pb-5 sm:pb-0 mb-4">
      <div class="md:flex md:items-center md:justify-between">
        <h3 class="text-lg font-medium leading-6 text-gray-900"><%= @title %></h3>
        <!-- 
        <div class="mt-3 flex md:absolute md:top-3 md:right-0 md:mt-0">
          <button
            type="button"
            class="inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          >
            Share
          </button>
          <button
            type="button"
            class="ml-3 inline-flex items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          >
            Create
          </button>
        </div>
        -->
      </div>
      <div class="mt-4">
        <!-- Dropdown menu on small screens -->
        <div class="sm:hidden">
          <label for="current-tab" class="sr-only">Select a tab</label>
          <select
            id="current-tab"
            name="current-tab"
            class="block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
          >
            <%= for link <- @sublink do %>
              <option phx-click="navigate" phx-value-path={link.path} selected={link.selected}>
                <%= link.content %>
              </option>
            <% end %>
          </select>
        </div>
        <!-- Tabs at small breakpoint and up -->
        <div class="hidden sm:block">
          <nav class="-mb-px flex space-x-8">
            <%= for link <- @sublink do %>
              <%= render_slot(link, %{
                path: link.path,
                active: link.selected,
                content: Map.get(link, :content, "")
              }) %>
            <% end %>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  attr :content, :string, required: true
  attr :path, :string, required: true
  attr :active, :boolean, default: false

  def sub_nav_patch_link(assigns) do
    ~H"""
    <.link
      patch={@path}
      class={get_link_class(@active)}
      aria-current={
        if @active do
          "page"
        else
          nil
        end
      }
    >
      <%= @content %>
    </.link>
    """
  end

  defp get_link_class(true) do
    "border-indigo-500 text-indigo-600 whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm"
  end

  defp get_link_class(false) do
    "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm"
  end
end
