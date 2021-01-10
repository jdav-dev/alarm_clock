defmodule AlarmClockUiWeb.Router do
  use AlarmClockUiWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AlarmClockUiWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", AlarmClockUiWeb do
    pipe_through :browser

    live "/", PageLive, :index

    live_dashboard "/dashboard", metrics: AlarmClockUiWeb.Telemetry
  end
end
