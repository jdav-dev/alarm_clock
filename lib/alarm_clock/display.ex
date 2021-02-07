defmodule AlarmClock.Display do
  use Agent

  alias Phoenix.PubSub

  @topic "display"

  def start_link(_opts) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def write(value) do
    Agent.update(__MODULE__, fn
      ^value ->
        value

      _old_value ->
        PubSub.broadcast!(AlarmClock.PubSub, @topic, {__MODULE__, value})
        value
    end)
  end

  def subscribe do
    PubSub.subscribe(AlarmClock.PubSub, @topic)
  end

  def unsubscribe do
    PubSub.unsubscribe(AlarmClock.PubSub, @topic)
  end
end
