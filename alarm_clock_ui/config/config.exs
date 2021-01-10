import Config

config :alarm_clock_ui, AlarmClockUiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pOvmvA5QL0Yo/ck0yDL7deYI5qkUiqboi3FMlyR0q30B0lcuLIZd/7/7ixsWN8Ga",
  render_errors: [view: AlarmClockUiWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: AlarmClockUi.PubSub,
  live_view: [signing_salt: "rxjigxow"],
  server: true

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

if Mix.target() == :host or Mix.target() == :"" do
  import_config "host.exs"
else
  import_config "target.exs"
end
