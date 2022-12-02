import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/genex_remote start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :genex_remote, GenexRemoteWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/genex_remote/genex_remote.db
      """

  config :genex_remote, GenexRemote.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  gpg_home =
    System.get_env("GNUPGHOME") ||
      raise """
      environment variable GNUPGHOME is missing
      """

  gpg_bin =
    System.get_env("GNUPGBIN") ||
      raise """
      environment variable GNUPGBIN is missing
      """

  config :gpgmex,
    gpg_home: gpg_home,
    gpg_bin: gpg_bin

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :genex_remote, GenexRemoteWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## Configuring the mailer
  # Currently using my personal gmail account.
  # the token is passed into the mailer at the call site
  # because it changes often via the
  # `GenexRemote.Mailer.TokenRefresher` process
  config :genex_remote, GenexRemote.Mailer,
    adapter: Swoosh.Adapters.Mailgun,
    api_key: System.get_env("MAILGUN_API_KEY"),
    domain: "sandbox3c8518196e0a4218917f224c3a067f02.mailgun.org"

  config :swoosh, :api_client, Swoosh.ApiClient.Hackney
end
