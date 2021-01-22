defmodule AlarmClockFirmware.GpioLed do
  use GenServer

  alias AlarmClockFirmware.Led
  alias Circuits.GPIO

  @pin_number 12

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    with {:ok, gpio} <- GPIO.open(@pin_number, :output),
         :ok <- Led.subscribe() do
      send(self(), :init_gpio)
      {:ok, gpio}
    end
  end

  @impl GenServer
  def handle_info(:init_gpio, gpio) do
    GPIO.write(gpio, 0)
    {:noreply, gpio}
  end

  def handle_info({Led, :on}, gpio) do
    GPIO.write(gpio, 1)
    {:noreply, gpio}
  end

  def handle_info({Led, :off}, gpio) do
    GPIO.write(gpio, 0)
    {:noreply, gpio}
  end
end
