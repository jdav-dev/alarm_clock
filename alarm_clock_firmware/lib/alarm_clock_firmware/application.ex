defmodule AlarmClockFirmware.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Memento.stop()
    Memento.Schema.create([node()])
    Memento.start()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlarmClockFirmware.Supervisor]

    children =
      [
        {Phoenix.PubSub, name: AlarmClockFirmware.PubSub},
        AlarmClockFirmware.Button,
        AlarmClockFirmware.Display,
        AlarmClockFirmware.Led,
        AlarmClockFirmware.NetworkStream,
        AlarmClockFirmware.Scheduler
      ] ++ children(target())

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      AlarmClockFirmware.display_time("Etc/UTC")
      {:ok, pid}
    end
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      AlarmClockFirmware.DisplayLogger,
      AlarmClockFirmware.LedLogger
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      AlarmClockFirmware.GpioButton,
      AlarmClockFirmware.GpioLed,
      AlarmClockFirmware.SevenSegmentDisplay
    ]
  end

  def target do
    Application.get_env(:alarm_clock_firmware, :target)
  end
end
