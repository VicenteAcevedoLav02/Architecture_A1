# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :architecture_a1,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :architecture_a1, ArchitectureA1Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ArchitectureA1Web.ErrorHTML, json: ArchitectureA1Web.ErrorJSON],
    layout: false
  ],
  pubsub_server: ArchitectureA1.PubSub,
  live_view: [signing_salt: "L1kUEEt5"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :architecture_a1, ArchitectureA1.Mailer, adapter: Swoosh.Adapters.Local

# Cache via Redis-Nebulex Config
redis_url = System.get_env("REDIS_URL", "redis://redis:6379")

config :architecture_a1, ArchitectureA1.Cache.NebulexImpl,
  adapter: Nebulex.Adapters.Redis,
  conn_opts: [url: redis_url],
  pool_size: 5

# config :architecture_a1, :cache_module, ArchitectureA1.Cache.NebulexImpl
if System.get_env("REDIS_URL") && System.get_env("USE_REDIS") != "false" do
  config :architecture_a1, :cache_module, ArchitectureA1.Cache.NebulexImpl
else
  config :architecture_a1, :cache_module, ArchitectureA1.Cache.NoopImpl
end

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  architecture_a1: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  architecture_a1: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
