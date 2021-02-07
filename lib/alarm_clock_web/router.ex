defmodule AlarmClockWeb.Router do
  use AlarmClockWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AlarmClockWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", AlarmClockWeb do
    pipe_through :browser

    live "/", PageLive, :index

    live_dashboard "/dashboard", metrics: AlarmClockWeb.Telemetry
  end
end
