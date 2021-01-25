defmodule AlarmClockUiWeb.PageLive do
  use AlarmClockUiWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <section class="row">
      <article class="column">
        <h2>Button</h2>
        <button class="button<%= unless @led, do: " button-outline"%>" phx-click="button"></button>
      </article>
    </section>

    <section class="row">
      <article class="column">
        <h2>Display</h2>
        <%= live_render @socket, AdafruitLedBackpack.SevenSegmentLive, id: "display" %>
      </article>
    </section>

    <section class="row">
      <article class="column">
        <h2>Jobs</h2>
        <pre><code><%= @jobs %></code></pre>
      </article>
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    jobs = inspect([], pretty: true, limit: :infinity)
    {:ok, assign(socket, display: nil, jobs: jobs, led: false, query: "")}
  end

  @impl Phoenix.LiveView
  def handle_event("button", _params, socket) do
    {:noreply, put_flash(socket, :info, "Button pressed")}
  end
end
