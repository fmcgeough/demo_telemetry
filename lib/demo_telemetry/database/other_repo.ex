defmodule DemoTelemetry.Database.OtherRepo do
  use Ecto.Repo,
    otp_app: :demo_telemetry,
    adapter: Ecto.Adapters.Postgres
end
