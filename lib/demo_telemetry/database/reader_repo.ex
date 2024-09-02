defmodule DemoTelemetry.Database.ReaderRepo do
  @moduledoc """
  Read replica
  """
  use Ecto.Repo,
    otp_app: :demo_telemetry,
    adapter: Ecto.Adapters.Postgres,
    read_only: true
end
