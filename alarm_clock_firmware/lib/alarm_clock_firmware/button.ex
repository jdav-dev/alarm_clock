defmodule AlarmClockFirmware.Button do
  use Agent

  alias Phoenix.PubSub

  @topic "button"

  def start_link(_opts) do
    Agent.start_link(fn -> false end, name: __MODULE__)
  end

  def press do
    Agent.update(__MODULE__, fn
      false ->
        PubSub.broadcast!(AlarmClockFirmware.PubSub, @topic, {__MODULE__, :pressed})
        true

      true ->
        true
    end)
  end

  def press_and_release(hold \\ 100) do
    press()
    Process.sleep(hold)
    release()
  end

  def release do
    Agent.update(__MODULE__, fn
      true ->
        PubSub.broadcast!(AlarmClockFirmware.PubSub, @topic, {__MODULE__, :released})
        false

      false ->
        false
    end)
  end

  def subscribe do
    PubSub.subscribe(AlarmClockFirmware.PubSub, @topic)
  end

  def unsubscribe do
    PubSub.unsubscribe(AlarmClockFirmware.PubSub, @topic)
  end
end
