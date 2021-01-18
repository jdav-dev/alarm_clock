defmodule AlarmClockFirmware.GpioButton do
  use GenServer

  alias AlarmClockFirmware.Button
  alias Circuits.GPIO

  @pin_number 6

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    case GPIO.open(@pin_number, :input) do
      {:ok, gpio} ->
        send(self(), :init_gpio)
        {:ok, gpio}

      error ->
        {:stop, error}
    end
  end

  @impl GenServer
  def handle_info(:init_gpio, gpio) do
    GPIO.set_pull_mode(gpio, :pulldown)
    GPIO.set_interrupts(gpio, :both)
    {:noreply, gpio}
  end

  def handle_info({:circuits_gpio, @pin_number, _timestamp, 1}, gpio) do
    Button.press()
    {:noreply, gpio}
  end

  def handle_info({:circuits_gpio, @pin_number, _timestamp, 0}, gpio) do
    Button.release()
    {:noreply, gpio}
  end
end
