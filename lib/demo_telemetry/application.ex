defmodule DemoTelemetry.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DemoTelemetry.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Since this is a simple library to show some aspects of Ecto telemetry we have
  only two child processes for our application.

  - Metrics.Instrumenter - this is the module that will receive Ecto Database Activity
  events. It's a good idea to hook into the telemetry system from a supervised
  process. This ensures that if the process restarts the code will attempt to
  hook into the telemetry system again.
  - Database.Supervisor - This is just a standard practice I use in Elixir. Instead
  of having Ecto.Repos directly under an application I put them under their own
  Supervisor. This allows better handling of the situation where a database connection
  is lost. That's not demonstrated in this library though.
  """
  def children do
    [
      DemoTelemetry.Metrics.Instrumenter,
      DemoTelemetry.Database.Supervisor
    ]
  end
end
