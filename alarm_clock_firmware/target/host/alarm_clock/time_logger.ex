defmodule AlarmClockFirmware.TimeLogger do
  require Logger

  def log_now(time_zone) do
    now = DateTime.utc_now()

    now
    |> DateTime.shift_zone!(time_zone)
    |> Calendar.strftime("%I:%M %p")
    |> Logger.info()
  end
end
