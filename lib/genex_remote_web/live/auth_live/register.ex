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
      {:ok, account, challenge_changeset} ->
        {:noreply,
         socket
         |> assign(account: account, challenge_changeset: challenge_changeset)
         |> push_patch(to: Routes.auth_register_path(socket, :validate), replace: true)}

      {:error, changeset} ->
        {:noreply,
         socket |> put_flash(:error, "fix the following errors") |> assign(changeset: changeset)}
    end
  end

  @impl true
  def handle_event("submit_proof", %{"account" => params}, socket) do
    # token = Auth.generate_login_token()
    case Auth.submit_challenge(socket.assigns.account, params) do
      {:ok, account} ->
        Auth.send_magic_link(account.email)

        {:noreply,
         push_patch(socket, to: Routes.auth_register_path(socket, :success), replace: true)}

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
        An account on Genex requires a GPG public key.

        TODO: explain how to create a GPG key

        Once you add your public key, you'll get back an encrypted message that you'll need to decrypt and send back.
        Doing this verifies that you hold the private key for the uploaded public key thus it is in fact you.

        Lastly, you'll get an email to validate you own the email address and then you'll verified account.
      </p>
    </div>

    <div :if={@live_action == :register}>
      <.form :let={f} for={@changeset} phx-submit="register">
        <%= label(f, :public_key, "Public Key") %>
        <%= textarea(f, :public_key, placeholder: "Enter your Public Key", rows: "45", cols: "10") %>
        <%= error_tag(f, :public_key) %>

        <%= submit("Register") %>
      </.form>
    </div>

    <div :if={@live_action == :validate}>
      <p>To prove you own this key, decrypt the following message a submit the decrtyped value</p>
      <pre> <%= @account.encrypted_challenge %> </pre>
      <.form :let={f} for={@challenge_changeset} phx-submit="submit_proof">
        <%= label(f, :challenge, "Decrypted Challenge") %>
        <%= text_input(f, :challenge) %>
        <%= error_tag(f, :challenge) %>

        <%= submit("Prove") %>
      </.form>
    </div>

    <div :if={@live_action == :success}>
      <p>
        Nice work! Your should now recieve an email at the email address attached to the public key with a link to login
      </p>

      <p><button>Resend Link</button></p>
    </div>
    """
  end
end
