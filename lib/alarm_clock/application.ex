defmodule AlarmClock.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    if path = Application.get_env(:mnesia, :dir) do
      :ok = File.mkdir_p!(path)
    end

    # Create the Schema
    Memento.stop()
    Memento.Schema.create([node()])
    Memento.start()

    children =
      [
        # Children for all targets

        # Start the Telemetry supervisor
        AlarmClockWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: AlarmClock.PubSub},
        # Start the Endpoint (http/https)
        AlarmClockWeb.Endpoint,
        AlarmClock.Button,
        AlarmClock.Led,
        AlarmClock.NetworkStream,
        AlarmClock.Scheduler
      ] ++ children(target())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlarmClock.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      AlarmClock.init!()
      {:ok, pid}
    end
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      AlarmClock.LedLogger
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      AlarmClock.Display,
      AlarmClock.GpioButton,
      AlarmClock.GpioLed
    ]
  end

  def target do
    Application.get_env(:alarm_clock, :target)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AlarmClockWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
