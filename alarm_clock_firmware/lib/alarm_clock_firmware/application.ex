defmodule AlarmClockFirmware.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlarmClockFirmware.Supervisor]

    children =
      [
        AlarmClockFirmware.Scheduler
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: AlarmClockFirmware.Worker.start_link(arg)
      # {AlarmClockFirmware.Worker, arg},
    ]
  end

  def children(_target) do
    [
      {AlarmClockFirmware.Led, 12},
      {AlarmClockFirmware.Button,
       pin_number: 5, push_fun: fn -> AlarmClockFirmware.Led.toggle(12) end}
    ]
  end

  def target do
    Application.get_env(:alarm_clock_firmware, :target)
  end
end
