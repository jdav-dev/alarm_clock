import Config

# Add configuration that is only needed when running on the host here.

config :alarm_clock_firmware, AlarmClockFirmware.NetworkStream, recordings_dir: "recordings"

config :mnesia, dir: '.mnesia/#{Mix.env()}/#{node()}'
