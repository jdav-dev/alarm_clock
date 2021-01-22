defmodule AlarmClockFirmware do
  @moduledoc """
  Documentation for AlarmClockFirmware.
  """

  alias AlarmClockFirmware.Display

  def display_time(time_zone) do
    now = DateTime.utc_now()

    now
    |> DateTime.shift_zone!(time_zone)
    |> Calendar.strftime("%I:%M")
    |> String.trim_leading("0")
    |> Display.write()
  end
end
