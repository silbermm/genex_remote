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
              <img
                class="h-10 w-auto"
                src={Routes.static_path(Endpoint, "/images/logo.png")}
                alt=""
              />
            </.link>
            <div class="ml-10 hidden space-x-8 lg:block">
              <%= if @account do %>
                <.link
                  navigate={Routes.profile_index_path(Endpoint, :index)}
                  class="text-base font-medium text-white hover:text-indigo-50"
                >
                  Profile
                </.link>
              <% end %>
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
end
