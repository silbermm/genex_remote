defmodule GenexRemoteWeb.AuthLive.Login do
  use GenexRemoteWeb, :live_view

  alias GenexRemote.Auth

  defstruct [:email]

  @types %{email: :string}

  @impl true
  def mount(_params, _session, socket) do
    changeset = changeset(%{})
    {:ok, assign(socket, page_title: "Login", changeset: changeset)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("login", %{"login" => %{"email" => email} = params}, socket) do
    params
    |> changeset()
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
      {:ok, _} ->
        Auth.send_magic_link(email)

        {:noreply,
         socket
         |> put_flash(:success, "Look for an email")
         |> push_patch(to: Routes.auth_login_path(socket, :email))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Login</h1>

    <%= if @live_action == :login do %>
      <div>
        <p>
          To login to Genex, just put your registered email address in the field.

          If your email is registered, you'll get an email with a link to login with.
        </p>
      </div>

      <.form :let={f} for={@changeset} phx-submit="login">
        <%= label(f, :email, "Email") %>
        <%= text_input(f, :email, required: true) %>
        <%= error_tag(f, :email) %>
        <%= submit("Login") %>
      </.form>
    <% end %>

    <%= if @live_action == :email do %>
      <div>
        <p>
          Check your email for a login link
        </p>
      </div>
    <% end %>
    """
  end

  defp changeset(params) do
    {%__MODULE__{}, @types}
    |> Ecto.Changeset.cast(params, Map.keys(@types))
    |> Ecto.Changeset.validate_required([:email])
    |> Ecto.Changeset.validate_format(:email, ~r/@/, message: "must be a valid email")
  end
end
