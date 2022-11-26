defmodule GenexRemote.Mailer.TokenRefresher do
  @moduledoc """
  Periodically refreshes the gmail tokens and then stores
  the new tokens in the DB.

  Tokens expire after 16 hours, so this refreshes them
  after 16 hours.

  Token was generated initially via the oauth playground and 
  inserted into the DB manually.

  https://developers.google.com/oauthplayground/
  """
  use GenServer

  require Logger

  # 16 hours
  @send_after 57_000_000
  @log_prefix "TokenRefresher | "

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_) do
    # grab token and refresh token from DB
    # set in state
    tokens = GenexRemote.Settings.get_gmail_tokens()

    {:ok, %{token: get_in(tokens, ["token"]), refresh_token: get_in(tokens, ["refresh_token"])},
     {:continue, :refresh}}
  end

  def current_token(), do: GenServer.call(__MODULE__, :current_token)

  @impl true
  def handle_call(:current_token, _from, state) do
    {:reply, state.token, state}
  end

  @impl true
  def handle_continue(:refresh, state) do
    new_state = refresh_tokens(state)

    Process.send_after(__MODULE__, :refresh, @send_after)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:refresh, state) do
    new_state = refresh_tokens(state)

    Process.send_after(__MODULE__, :refresh, @send_after)
    {:noreply, new_state}
  end

  defp refresh_tokens(%{token: _token, refresh_token: refresh_token} = state)
       when is_nil(refresh_token) or refresh_token == "" do
    Logger.error("#{@log_prefix} token is empty")
    state
  end

  defp refresh_tokens(%{token: _token, refresh_token: refresh_token} = state) do
    res =
      Req.post("https://oauth2.googleapis.com/token",
        form: [
          client_secret: client_secret(),
          client_id: client_id(),
          grant_type: "refresh_token",
          refresh_token: refresh_token
        ]
      )

    case res do
      {:ok, %{body: body}} ->
        new_state = %{token: Map.get(body, "access_token"), refresh_token: refresh_token}
        _ = GenexRemote.Settings.update_gmail_tokens(new_state)
        new_state

      err ->
        Logger.error("#{@log_prefix} unable to refresh token #{inspect(err)}")
        state
    end
  end

  defp client_id() do
    mailer_config = Application.get_env(:genex, GenexRemote.Mailer)

    if mailer_config == nil do
      ""
    else
      Keyword.get(mailer_config, :client_id, "")
    end
  end

  defp client_secret() do
    mailer_config = Application.get_env(:genex, GenexRemote.Mailer)

    if mailer_config == nil do
      ""
    else
      Keyword.get(mailer_config, :client_secret, "")
    end
  end
end
