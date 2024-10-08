import Config

config :demo_telemetry, DemoTelemetry.Database.Repo,
  database: "demo_telemetry_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  telemetry_prefix: [:demo_telemetry, :primary]

config :demo_telemetry, DemoTelemetry.Database.ReaderRepo,
  database: "demo_telemetry_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  telemetry_prefix: [:demo_telemetry, :replica]

config :demo_telemetry, DemoTelemetry.Database.OtherRepo,
  database: "demo_telemetry_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
