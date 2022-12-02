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
  alias GenexRemoteWeb.Components.AuthLayout

  on_mount {GenexRemoteWeb.Hooks.AuthenticatedRedirect, :default}

  @impl true
  # if the url param has an account_id, try to build the correct
  # validation changeset.
  def mount(%{"account_id" => account_id}, _session, socket) do
    case Auth.build_challenge_changeset(account_id) do
      {:ok, account, challenge_changeset} ->
        {:ok, assign(socket, account: account, challenge_changeset: challenge_changeset)}

      {:error, reason} ->
        IO.inspect("ERR")
        {:ok, assign(socket, validate_error: reason)}
    end
  end

  def mount(_params, _session, socket) do
    account_changeset = Auth.new_blank_account()
    {:ok, assign(socket, changeset: account_changeset)}
  end

  @impl true
  def handle_params(_, _, socket) do
    if socket.assigns.live_action == :validate do
      if Map.has_key?(socket.assigns, :account) && !is_nil(socket.assigns.account) do
        {:noreply, socket}
      else
        if Map.has_key?(socket.assigns, :validate_error) do
          {:noreply,
           socket
           |> put_flash(:error, socket.assigns.validate_error)
           |> assign(changeset: Auth.new_blank_account())
           |> push_patch(to: Routes.auth_register_path(socket, :register))}
        else
          {:noreply,
           socket
           |> put_flash(:info, "enter the following info before validating")
           |> push_patch(to: Routes.auth_register_path(socket, :register))}
        end
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
         |> push_patch(
           to: Routes.auth_register_path(socket, :validate, account_id: account.id),
           replace: true
         )}

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
    <%= unless Map.has_key?(@socket, :validate_error) do %>
      <.form :let={f} :if={@live_action == :register} for={@changeset} phx-submit="register">
        <AuthLayout.register form={f}>
          <:header>
            <AuthLayout.header title="Register">
              <:description>
                <.page_description />
              </:description>
            </AuthLayout.header>
          </:header>
        </AuthLayout.register>
      </.form>

      <.form
        :let={f}
        :if={@live_action == :validate}
        for={@challenge_changeset}
        phx-submit="submit_proof"
      >
        <AuthLayout.register_prove form={f} encrypted_challenge={@account.encrypted_challenge}>
          <:header>
            <AuthLayout.header title="Register">
              <:description>
                <.page_description />
              </:description>
            </AuthLayout.header>
          </:header>
        </AuthLayout.register_prove>
      </.form>

      <div :if={@live_action == :success}>
        <p>
          Nice work! Your should now recieve an email at the email address attached to the public key with a link to login
        </p>

        <p><button>Resend Link</button></p>
      </div>
    <% end %>
    """
  end

  defp page_description(assigns) do
    ~H"""
    <span> An account on Genex requires a GPG public key. </span>

    <span class="block pt-2"> TODO: explain how to create a GPG key </span>

    <span class="block pt-2">
      Once you add your public key, you'll get back an encrypted message that you'll need to decrypt and send back.
      Doing this verifies that you hold the private key for the uploaded public key thus it is in fact you.
    </span>

    <span class="block pt-2">
      Lastly, you'll get an email to validate you own the email address and then you'll verified account.
    </span>
    """
  end
end
