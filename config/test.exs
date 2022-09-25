import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :genex_remote, GenexRemote.Repo,
  database: Path.expand("../genex_remote_test.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :genex_remote, GenexRemoteWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "RlS+3kmuZNU09k0xSO9c+dMDoSie3HJSrLt2C0f1UdnAvZbSnmhnHbDp4yz1vS6z",
  server: false

# In test we don't send emails.
config :genex_remote, GenexRemote.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
