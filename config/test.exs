import Config

config :demo_telemetry, DemoTelemetry.Database.Repo,
  database: "demo_telemetry_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  telemetry_prefix: [:demo_telemetry, :primary],
  pool: Ecto.Adapters.SQL.Sandbox

config :demo_telemetry, DemoTelemetry.Database.ReaderRepo,
  database: "demo_telemetry_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  telemetry_prefix: [:demo_telemetry, :replica],
  pool: Ecto.Adapters.SQL.Sandbox

config :demo_telemetry, DemoTelemetry.Database.OtherRepo,
  database: "demo_telemetry_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :demo_telemetry, log_telemetry_info: false

config :logger, level: :warning
