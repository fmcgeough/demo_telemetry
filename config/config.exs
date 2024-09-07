import Config

config :demo_telemetry,
  ecto_repos: [DemoTelemetry.Database.Repo]

import_config "#{config_env()}.exs"
