defmodule AlarmClockFirmware.DisplayLogger do
  use GenServer

  alias AlarmClockFirmware.Display

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    with :ok <- Display.subscribe() do
      {:ok, nil}
    end
  end

  @impl GenServer
  def handle_info({Display, value}, state) do
    Logger.debug("Display #{inspect(value)}")
    {:noreply, state}
  end
end
