defmodule AlarmClock do
  @moduledoc """
  Documentation for AlarmClock.
  """

  alias AlarmClock.Display

  @asound_state "/root/asound.state"

  def display_time(time_zone) do
    time_zone
    |> DateTime.now!()
    |> Display.show(:colon)
  end

  def init! do
    restore_volume()
    :ok = Display.set_brightness(0)
    :ok = display_time("America/New_York")
    :ok
  end

  # If the @asound_state file doesn't exist, we MUST play a file with `aplay` before the sound
  # card is visible to `amixer`.  The played file can be empty.  Then set the default volume and
  # write the initial @asound_state file.
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
