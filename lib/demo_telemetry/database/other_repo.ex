defmodule DemoTelemetry.Database.OtherRepo do
  @moduledoc """
  Repo to demonstrate Ecto event named using Ecto.Repo module name
  """
  use Ecto.Repo,
    otp_app: :demo_telemetry,
    adapter: Ecto.Adapters.Postgres
end
