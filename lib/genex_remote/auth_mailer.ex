defmodule GenexRemote.AuthMailer do
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
    |> Repo.update()
    |> case do
      {:error, changeset} ->
        Logger.error("#{@log_prefix} unable to update the account")
        {:stop, :normal, state}

      {:ok, updated_account} ->
        {:noreply, %{state | token: token}, {:continue, :send_mail}}
    end
  end

  @impl true
  def handle_continue(:send_mail, %{account: account, email: email, token: token} = state) do
    Logger.info("#{@log_prefix} send magic link")

    Email.new()
    |> Email.to({email, email})
    |> Email.from({"Genex", "noreply@genex.io"})
    |> Email.subject("Login to your account")
    |> Email.html_body(
      ~s{<h1>Follow the link to login to your account</h1> <a href="http://localhost:4000/login/#{token}/email/#{email}"> Login </a>}
    )
    |> Email.text_body(
      "Follow the link to login to your account. http://localhost:4000/login/#{token}/email/#{email} \n"
    )
    |> GenexRemote.Mailer.deliver()

    {:stop, :normal, state}
  end

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
