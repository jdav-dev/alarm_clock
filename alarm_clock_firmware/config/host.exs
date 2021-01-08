import Config

# Add configuration that is only needed when running on the host here.

config :alarm_clock_firmware, AlarmClockFirmware.Scheduler,
  jobs: [
    display_time: [
      schedule: "* * * * *",
      task: {AlarmClockFirmware.TimeLogger, :log_now, []}
    ]
  ]
