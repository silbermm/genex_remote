defmodule GenexRemoteWeb.AuthLive.Register do
  @moduledoc """
  Handles registration for the site.

  The live_action can be one of:
    * :register
    * :validate

  :register should display the registration form.

  Once the registration form is submitted, the user is pushed to
  the :validate live_action where they are expected to answer the
  challenge.
  """

  use GenexRemoteWeb, :live_view

  alias GenexRemote.Auth

  @impl true
  def mount(_params, _session, socket) do
    IO.inspect("MOUNT")
    account_changeset = Auth.new_blank_account()
    {:ok, assign(socket, changeset: account_changeset)}
  end

  @impl true
  def handle_params(_parms, _, socket) do
    if socket.assigns.live_action == :validate do
      if Map.has_key?(socket.assigns, :account) do
        {:noreply, socket}
      else
        {:noreply,
         socket
         |> put_flash(:info, "enter the following info before validating")
         |> push_patch(to: Routes.auth_register_path(socket, :register))}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("register", %{"account" => params}, socket) do
    case Auth.create_account(params) do
      {:ok, account} ->
        # TODO: return an encrypted message to make sure the
        # user actually owns the private key
        {:noreply,
         socket
         |> assign(:account, account)
         |> push_patch(to: Routes.auth_register_path(socket, :validate), replace: true)}

      {:error, changeset} ->
        {:noreply,
         socket |> put_flash(:error, "fix the following errors") |> assign(changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Register a new account</h1>

    <div>
      <p>
        An account on Genex requires a GPG public key and the associated email address.

        TODO: explain how to create a GPG key

        Once you add those things, you'll get back an encrypted message that you'll need to decrypt and send back.
        Doing this verifys that you hold the private key for the uploaded public key thus it is in fact you.
      </p>
    </div>

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
