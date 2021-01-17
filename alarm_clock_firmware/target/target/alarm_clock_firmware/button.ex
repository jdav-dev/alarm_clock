defmodule AlarmClockFirmware.Button do
  use GenServer

  alias Circuits.GPIO
  alias Phoenix.PubSub

  @pin_number 6
  @topic "gpio_button"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe do
    PubSub.subscribe(AlarmClockFirmware.PubSub, @topic)
  end

  def unsubscribe do
    PubSub.unsubscribe(AlarmClockFirmware.PubSub, @topic)
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
    PubSub.broadcast!(AlarmClockFirmware.PubSub, @topic, {__MODULE__, :pressed})
    {:noreply, gpio}
  end

  def handle_info({:circuits_gpio, @pin_number, _timestamp, 0}, gpio) do
    PubSub.broadcast!(AlarmClockFirmware.PubSub, @topic, {__MODULE__, :released})
    {:noreply, gpio}
  end
end
