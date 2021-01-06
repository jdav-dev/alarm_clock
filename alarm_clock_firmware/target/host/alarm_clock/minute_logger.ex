defmodule AlarmClockFirmware.MinuteLogger do
  require Logger

  @time_zone Application.compile_env!(:alarm_clock_firmware, :time_zone)

  def log_now do
    now = DateTime.utc_now()

    now
    |> DateTime.shift_zone!(@time_zone)
    |> Calendar.strftime("%I:%M %p")
    |> Logger.info()
  end
end
