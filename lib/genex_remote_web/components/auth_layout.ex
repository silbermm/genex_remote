defmodule GenexRemoteWeb.Components.AuthLayout do
  use Phoenix.Component
  use Phoenix.HTML
  import GenexRemoteWeb.ErrorHelpers

  attr :title, :string, required: true
  slot(:description, required: true)

  def header(assigns) do
    ~H"""
    <h3 class="text-lg font-medium leading-6 text-gray-900"><%= @title %></h3>
    <p class="mt-1 mb-6 max-w-2xl text-sm text-gray-500">
      <%= render_slot(@description) %>
    </p>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :encrypted_challenge, :string, required: true
  slot(:header, required: true)
  @doc "The for proving key ownership"
  def register_prove(assigns) do
    ~H"""
    <div class="space-y-8 divide-y divide-gray-200 sm:space-y-5">
      <div>
        <%= render_slot(@header) %>
        <div class="mt-6 grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
          <div class="sm:col-span-3">
            <pre> <%= @encrypted_challenge %> </pre>

            <%= label(@form, :challenge, "Decrypted Challenge",
              class: "block text-sm font-medium text-gray-700"
            ) %>

            <%= text_input(@form, :challenge,
              required: true,
              class:
                "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            ) %>
            <p class="block text-sm text-gray-500"><%= error_tag(@form, :challenge) %></p>
          </div>
        </div>
        <div>
          <div class="pt-1">
            <div class="flex justify-start">
              <%= submit("Prove",
                class:
                  "minline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              ) %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  slot(:header, required: true)
  @doc "Render the Registration form"
  def register(assigns) do
    ~H"""
    <div class="space-y-8 divide-y divide-gray-200 sm:space-y-5">
      <div>
        <%= render_slot(@header) %>
        <div class="mt-6 grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
          <div class="sm:col-span-3">
            <%= label(@form, :public_key, "Public Key",
              class: "block text-sm font-medium text-gray-700"
            ) %>

            <%= textarea(@form, :public_key,
              required: true,
              placeholder: "Enter your public key",
              class:
                "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
              rows: 20,
              col: 20
            ) %>
            <p class="block text-sm text-gray-500"><%= error_tag(@form, :public_key) %></p>
          </div>
        </div>
        <div>
          <div class="pt-1">
            <div class="flex justify-start">
              <%= submit("Register",
                class:
                  "minline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              ) %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  slot(:header, required: true)
  @doc "Render the Login form"
  def login(assigns) do
    ~H"""
    <div class="space-y-8 divide-y divide-gray-200 sm:space-y-5">
      <div>
        <%= render_slot(@header) %>

        <div class="mt-6 grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
          <div class="sm:col-span-3">
            <%= label(@form, :email, "Email", class: "block text-sm font-medium text-gray-700") %>

            <%= text_input(@form, :email,
              required: true,
              placeholder: "user@mail.com",
              class:
                "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            ) %>
            <p class="block text-sm text-gray-500"><%= error_tag(@form, :email) %></p>
          </div>
        </div>
        <div>
          <div class="pt-1">
            <div class="flex justify-start">
              <%= submit("Login",
                class:
                  "minline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              ) %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
