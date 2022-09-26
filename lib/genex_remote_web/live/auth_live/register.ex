defmodule GenexRemoteWeb.AuthLive.Register do
  use GenexRemoteWeb, :live_view

  alias GenexRemote.Auth

  @impl true
  def mount(_params, _session, socket) do
    account_changeset = Auth.new_blank_account()
    {:ok, assign(socket, changeset: account_changeset)}
  end

  @impl true
  def handle_event("register", %{"account" => params}, socket) do
    case Auth.create_account(params) do
      {:ok, _account} ->
        # TODO: return an encrypted message to make sure the
        # user actually owns the private key
        {:noreply, put_flash(socket, :info, "success")}

      {:error, changeset} ->
        {:noreply,
         socket |> put_flash(:error, "fix the following errors") |> assign(changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Register a new account</h1>

    <.form :let={f} for={@changeset} phx-submit="register">
      <%= label(f, :email, "Email") %>
      <%= text_input(f, :email) %>
      <%= error_tag(f, :email) %>

      <%= label(f, :public_key, "Public Key") %>
      <%= textarea(f, :public_key, placeholder: "Enter your Public Key") %>
      <%= error_tag(f, :public_key) %>

      <%= submit("Register") %>
    </.form>
    """
  end
end
