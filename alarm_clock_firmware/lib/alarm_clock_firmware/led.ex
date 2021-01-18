defmodule AlarmClockFirmware.Led do
  use GenServer

  alias AlarmClockFirmware.Button
  alias Phoenix.PubSub

  @topic "led"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def off do
    GenServer.call(__MODULE__, :off)
  end

  def on do
    GenServer.call(__MODULE__, :on)
  end

  def subscribe do
    PubSub.subscribe(AlarmClockFirmware.PubSub, @topic)
  end

  def unsubscribe do
    PubSub.unsubscribe(AlarmClockFirmware.PubSub, @topic)
  end

  @impl GenServer
  def init(_opts) do
    with :ok <- Button.subscribe() do
      {:ok, %{}}
    end
  end

  @impl GenServer
  def handle_call(:on, {pid, _tag}, monitors) do
    if monitors == %{} do
      PubSub.broadcast!(AlarmClockFirmware.PubSub, @topic, {__MODULE__, :on})
    end

    {:reply, :ok, Map.put_new_lazy(monitors, pid, fn -> Process.monitor(pid) end)}
  end

  def handle_call(:off, {pid, _tag}, monitors) do
    {monitor_ref, remaining_monitors} = Map.pop(monitors, pid)

    if monitor_ref do
      Process.demonitor(monitor_ref)

      if remaining_monitors == %{} do
        PubSub.broadcast!(AlarmClockFirmware.PubSub, @topic, {__MODULE__, :off})
      end
    end

    {:reply, :ok, remaining_monitors}
  end

  @impl GenServer
  def handle_info({Button, :pressed}, monitors) do
    {:reply, :ok, updated_monitors} = handle_call(:on, {self(), nil}, monitors)
    {:noreply, updated_monitors}
  end

  def handle_info({Button, :released}, monitors) do
    {:reply, :ok, updated_monitors} = handle_call(:off, {self(), nil}, monitors)
    {:noreply, updated_monitors}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, monitors) do
    {:reply, :ok, updated_monitors} = handle_call(:off, {pid, nil}, monitors)
    {:noreply, updated_monitors}
  end
end
