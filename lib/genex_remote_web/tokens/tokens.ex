defmodule GenexRemoteWeb.Tokens do
  @moduledoc """
  Simple module that handles signing and verifiying tokens
  """

  @auth_token_salt "account auth"

  # 30 days
  @auth_token_age 86400 * 30

  def sign_auth_token(account_id) do
    Phoenix.Token.sign(GenexRemoteWeb.Endpoint, @auth_token_salt, account_id, max_age: @auth_token_age)
  end

  def verify_auth_token(auth_token) do
    Phoenix.Token.verify(GenexRemoteWeb.Endpoint, @auth_token_salt, auth_token)
  end
end
