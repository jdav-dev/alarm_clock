defmodule AlarmClockFirmware.Led do
  use GenServer

  alias AlarmClockFirmware.Button
  alias Circuits.GPIO

  @pin_number 12

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def on do
    GenServer.cast(__MODULE__, :on)
  end

  def off do
    GenServer.cast(__MODULE__, :off)
  end

  @impl GenServer
  def init(_opts) do
    case GPIO.open(@pin_number, :output) do
      {:ok, gpio} ->
        send(self(), :init_gpio)
        Button.subscribe()
        {:ok, %{gpio: gpio, on: false}}

      error ->
        {:stop, error}
    end
  end

  @impl GenServer
  def handle_info(:init_gpio, %{gpio: gpio} = state) do
    GPIO.write(gpio, 0)
    {:noreply, state}
  end

  def handle_info({Button, :pressed}, state) do
    handle_cast(:on, state)
  end

  def handle_info({Button, :released}, state) do
    handle_cast(:off, state)
  end

  @impl GenServer
  def handle_cast(:on, %{gpio: gpio, on: false} = state) do
    GPIO.write(gpio, 1)
    {:noreply, %{state | on: true}}
  end

  def handle_cast(:off, %{gpio: gpio, on: true} = state) do
    GPIO.write(gpio, 0)
    {:noreply, %{state | on: false}}
  end

  def handle_cast(_call, state) do
    {:noreply, state}
  end
end
