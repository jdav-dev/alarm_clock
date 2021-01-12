defmodule AlarmClockFirmware.Button do
  use GenServer

  alias Circuits.GPIO

  require Logger

  def start_link(opts) when is_list(opts) do
    pin_number = Keyword.fetch!(opts, :pin_number)
    push_fun = opts[:push_fun]
    release_fun = opts[:release_fun]
    GenServer.start_link(__MODULE__, {pin_number, push_fun, release_fun}, name: name(pin_number))
  end

  defp name(pin_number), do: String.to_atom("button_#{pin_number}")

  @impl GenServer
  def init({pin_number, push_fun, release_fun}) do
    case GPIO.open(pin_number, :input) do
      {:ok, gpio} ->
        send(self(), :init_gpio)
        {:ok, %{gpio: gpio, pin_number: pin_number, push_fun: push_fun, release_fun: release_fun}}

      error ->
        {:stop, error}
    end
  end

  @impl GenServer
  def handle_info(:init_gpio, %{gpio: gpio} = state) do
    GPIO.set_pull_mode(gpio, :pulldown)
    GPIO.set_interrupts(gpio, :both)
    {:noreply, state}
  end

  def handle_info(
        {:circuits_gpio, pin_number, timestamp, 1},
        %{pin_number: pin_number, push_fun: push_fun} = state
      ) do
    Logger.debug("button #{pin_number} pressed at #{timestamp}")
    push_fun && push_fun.()
    {:noreply, state}
  end

  def handle_info(
        {:circuits_gpio, pin_number, timestamp, 0},
        %{pin_number: pin_number, release_fun: release_fun} = state
      ) do
    Logger.debug("button #{pin_number} released at #{timestamp}")
    release_fun && release_fun.()
    {:noreply, state}
  end

  def handle_info(call, state) do
    Logger.error("unmatched info: #{inspect(call)}")
    {:noreply, state}
  end
end
