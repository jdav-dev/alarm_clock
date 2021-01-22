defmodule AlarmClockFirmware.SevenSegmentDisplay do
  use GenServer

  alias AdafruitLedBackpack.SevenSegment
  alias AlarmClockFirmware.Display

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    with :ok <- Display.subscribe(),
         {:ok, pid} <- SevenSegment.start_link() do
      {:ok, pid}
    else
      error -> {:stop, error}
    end
  end

  @impl GenServer
  def handle_info({Display, value}, pid) when is_binary(value) do
    value_without_colon = String.replace(value, ":", "")

    with :ok <- SevenSegment.clear(),
         :ok <- SevenSegment.print_number_str(pid, value_without_colon),
         :ok <- SevenSegment.set_colon(pid, :on),
         :ok <- SevenSegment.write_display(pid) do
      {:noreply, pid}
    else
      error -> {:stop, error}
    end
  end

  # def handle_info({Display, value}, pid) when is_float(value) do
  #   with :ok <- SevenSegment.clear(),
  #        :ok <- SevenSegment.print_float(pid, value),
  #        :ok <- SevenSegment.set_colon(pid, :on),
  #        :ok <- SevenSegment.write_display(pid) do
  #     {:noreply, pid}
  #   else
  #     error -> {:stop, error}
  #   end
  # end

  # def handle_info({Display, value}, pid) when is_integer(value) do
  #   with :ok <- SevenSegment.clear(),
  #        :ok <- SevenSegment.print_hex(pid, value),
  #        :ok <- SevenSegment.set_colon(pid, :on),
  #        :ok <- SevenSegment.write_display(pid) do
  #     {:noreply, pid}
  #   else
  #     error -> {:stop, error}
  #   end
  # end

  def handle_info({Display, _value}, pid) do
    with :ok <- SevenSegment.clear(),
         :ok <- SevenSegment.print_number_str(pid, "----"),
         :ok <- SevenSegment.write_display(pid) do
      {:noreply, pid}
    else
      error -> {:stop, error}
    end
  end
end
