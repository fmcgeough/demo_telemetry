defmodule DemoTelemetry.Database.Supervisor do
  @moduledoc """
  Supervisor for database connections (Repos)
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, name: opts[:name] || __MODULE__)
  end

  def init(:ok) do
    children = [DemoTelemetry.Database.Repo, DemoTelemetry.Database.ReaderRepo, DemoTelemetry.Database.OtherRepo]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
