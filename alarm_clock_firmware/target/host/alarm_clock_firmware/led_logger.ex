defmodule AlarmClockFirmware.LedLogger do
  use GenServer

  alias AlarmClockFirmware.Led

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    with :ok <- Led.subscribe() do
      {:ok, nil}
    end
  end

  @impl GenServer
  def handle_info({Led, :on}, state) do
    Logger.debug("LED set to on")
    {:noreply, state}
  end

  def handle_info({Led, :off}, state) do
    Logger.debug("LED set to off")
    {:noreply, state}
  end
end
