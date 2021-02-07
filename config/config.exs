# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

config :alarm_clock, target: Mix.target()

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1611767868"

# Configures the endpoint
config :alarm_clock, AlarmClockWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MGcPpM1PcS5nXmf51pP53/H3TewdgjfW4Ck5iU4BvSLFVKsXo+Z/HGWHlYYLaMwK",
  render_errors: [view: AlarmClockWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: AlarmClock.PubSub,
  live_view: [signing_salt: "U0NiuIbM"]

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

# Configures Elixir's Logger
config :logger, RingLogger,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :alarm_clock, AlarmClock.Scheduler,
  overlap: false,
  run_strategy: Quantum.RunStrategy.Local,
  storage: QuantumStorageMnesia

if Mix.target() == :host or Mix.target() == :"" do
  import_config "host.exs"
else
  import_config "target.exs"
end
