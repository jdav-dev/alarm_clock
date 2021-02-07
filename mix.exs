defmodule AlarmClock.MixProject do
  use Mix.Project

  @app :alarm_clock
  @version "0.1.0"
  @all_targets [:rpi3]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      archives: [nerves_bootstrap: "~> 1.10"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: aliases(),
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [
        "phx.gen.secret": :host,
        "phx.server": :host,
        run: :host,
        test: :host
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {AlarmClock.Application, []},
      extra_applications: [:inets, :logger, :os_mon, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.6.0", runtime: false},
      {:shoehorn, "~> 0.7.0"},
      {:ring_logger, "~> 0.8.1"},
      {:toolshed, "~> 0.2.13"},
      {:phoenix, "~> 1.5.7"},
      {:phoenix_live_view, "~> 0.15.0"},
      {:floki, ">= 0.27.0", only: :test},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:tzdata, "~> 1.1"},
      {:quantum, "~> 3.3"},
      {:quantum_storage_mnesia, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:adafruit_led_backpack,
       github: "jdav-dev/adafruit_led_backpack", ref: "ff668e1960832a27cfef78419c739ab6155bb0c7"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.11.3", targets: @all_targets},
      {:nerves_pack, "~> 0.4.0", targets: @all_targets},
      {:circuits_gpio, "~> 0.4.6", targets: @all_targets},
      {:circuits_i2c, "~> 0.3.7", targets: @all_targets},

      # Dependencies for specific targets
      {:alarm_clock_rpi3,
       github: "jdav-dev/alarm_clock_rpi3", ref: "v1.13.3", runtime: false, targets: :rpi3},
      {:phoenix_live_reload, "~> 1.2", only: :dev, targets: :host}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"]
    ]
  end
end
