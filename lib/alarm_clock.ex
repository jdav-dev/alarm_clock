defmodule AlarmClock do
  @moduledoc """
  Documentation for AlarmClock.
  """

  alias AdafruitLedBackpack.SevenSegment

  @asound_state "/root/asound.state"

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

  def init! do
    restore_volume()
    :ok = set_brightness(0)
    :ok = display_time("Etc/UTC")
    :ok
  end

  defdelegate set_brightness(brightness), to: SevenSegment

  def restore_volume do
    case System.cmd("/usr/sbin/alsactl", ["--file", @asound_state, "restore"],
           env: [],
           stderr_to_stdout: true
         ) do
      {_result, 0} -> :ok
      error -> {:error, error}
    end
  end

  def set_volume(volume) when volume in 0..255 do
    with {_result, 0} <-
           System.cmd("/usr/bin/amixer", ["--card", "0", "sset", "'PCM',0", to_string(volume)]),
         {_result, 0} <-
           System.cmd("/usr/sbin/alsactl", ["--file", @asound_state, "store"]) do
      :ok
    else
      error -> {:error, error}
    end
  end
end
