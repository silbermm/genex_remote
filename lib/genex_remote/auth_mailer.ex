defmodule GenexRemote.AuthMailer do
  @moduledoc """
  Process that spins up when a new login link is requested
  via `GenexRemote.Auth.send_magic_link/1`.

  It takes an email address as an argument then:
    * looks up a valid account for that email
    * generates a login token
    * emails login token
    * terminates

  Supervised by a DynamicSupervisor `GenexRemote.DynamicSupervisors`
  """
  use GenServer, restart: :transient

  alias GenexRemote.Auth.Account
  alias GenexRemote.Repo
  import Ecto.Query
  alias Swoosh.Email

  require Logger

  @log_prefix "[AuthMailer] | "

  def start_link(email) do
    GenServer.start_link(__MODULE__, email)
  end

  @impl true
  def init(email) do
    Logger.info("#{@log_prefix} initialize magic link process")
    {:ok, %{email: email, token: nil, account: nil}, {:continue, :query}}
  end

  @impl true
  def handle_continue(:query, %{email: email} = state) do
    Logger.info("#{@log_prefix} get the account")

    email
    |> get_verified_account_by_email()
    |> case do
      nil ->
        Logger.info("#{@log_prefix} no account, exiting")
        {:stop, :normal, state}

      account ->
        {:noreply, %{state | account: account}, {:continue, :generate_token}}
    end
  end

  @impl true
  def handle_continue(:generate_token, %{account: account} = state) do
    Logger.info("#{@log_prefix} generate token")
    token = Account.generate_login_token()

    account
    |> Account.token_changeset(%{login_token: token})
    |> Repo.primary_write(:update)
    |> case do
      {:error, _changeset} ->
        Logger.error("#{@log_prefix} unable to update the account")
        {:stop, :normal, state}

      {:ok, _updated_account} ->
        {:noreply, %{state | token: token}, {:continue, :send_mail}}
    end
  end

  @impl true
  def handle_continue(:send_mail, %{email: email, token: token} = state) do
    Logger.info("#{@log_prefix} send magic link")

    host = GenexRemoteWeb.Endpoint.url()

    path =
      GenexRemoteWeb.Router.Helpers.session_path(
        GenexRemoteWeb.Endpoint,
        :create_from_token,
        token,
        email,
        []
      )

    Logger.info("#{@log_prefix} #{host <> path}")

    Email.new()
    |> Email.to({email, email})
    |> Email.from({"Genex", "noreply@genex.dev"})
    |> Email.subject("Login to your account")
    |> Email.html_body(
      ~s{<h1>Follow the link to login to your account</h1> <a href="#{host <> path}"> Login </a>}
    )
    |> Email.text_body("Follow the link to login to your account. #{host <> path} \n")
    |> GenexRemote.Mailer.deliver!()

    {:stop, :normal, state}
  end

  @impl true
  def terminate(:normal, state) do
    Logger.info("#{@log_prefix} cleanup and exit")
    {:ok, state}
  end

  defp get_verified_account_by_email(email) do
    query =
      from(a in Account,
        where: a.email == ^email,
        where: not is_nil(a.validated)
      )

    Repo.one(query)
  end
end
