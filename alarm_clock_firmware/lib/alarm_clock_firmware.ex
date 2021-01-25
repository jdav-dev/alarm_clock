defmodule AlarmClockFirmware do
  @moduledoc """
  Documentation for AlarmClockFirmware.
  """

  alias AdafruitLedBackpack.SevenSegment

  def display_time(time_zone) do
    now = DateTime.utc_now()

    value =
      now
      |> DateTime.shift_zone!(time_zone)
      |> Calendar.strftime("%I%M")
      |> String.trim_leading("0")

    with :ok <- SevenSegment.clear(),
         :ok <- SevenSegment.print_number_str(value),
         :ok <- SevenSegment.set_colon(:on) do
      SevenSegment.write_display()
    end
  end
end
