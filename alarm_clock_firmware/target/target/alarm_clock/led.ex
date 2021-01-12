defmodule AlarmClockFirmware.Led do
  use GenServer

  alias Circuits.GPIO

  def start_link(pin_number) do
    GenServer.start_link(__MODULE__, pin_number, name: name(pin_number))
  end

  defp name(pin_number), do: String.to_atom("led_#{pin_number}")

  def on(pin_number) do
    pin_number
    |> name()
    |> GenServer.cast(:on)
  end

  def off(pin_number) do
    pin_number
    |> name()
    |> GenServer.cast(:off)
  end

  def toggle(pin_number) do
    pin_number
    |> name()
    |> GenServer.cast(:toggle)
  end

  @impl GenServer
  def init(pin_number) do
    case GPIO.open(pin_number, :output) do
      {:ok, gpio} ->
        send(self(), :init_gpio)
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

  @impl GenServer
  def handle_cast(:on, %{gpio: gpio, on: false} = state) do
    GPIO.write(gpio, 1)
    {:noreply, %{state | on: true}}
  end

  def handle_cast(:off, %{gpio: gpio, on: true} = state) do
    GPIO.write(gpio, 0)
    {:noreply, %{state | on: false}}
  end

  def handle_cast(:toggle, %{on: false} = state) do
    handle_cast(:on, state)
  end

  def handle_cast(:toggle, %{on: true} = state) do
    handle_cast(:off, state)
  end

  def handle_cast(_call, state) do
    {:noreply, state}
  end
end
