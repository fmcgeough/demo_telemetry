defmodule TelemetryTestHelper do
  use ExUnit.CaseTemplate

  @moduledoc """
  Use in unit tests to ensure that an expected telemetry event is generated
  """

  alias DemoTelemetry.Metrics.Instrumenter

  @doc """
  Attach to telemetry system for a single event
  """
  def attach(event_name, test) do
    attach_many([event_name], test)
  end

  @doc """
  Attach to telemetry system for multiple events
  """
  def attach_many(events, test) do
    pid = self()
    :telemetry.attach_many(test, events, &__MODULE__.handle_event/4, pid)
    on_exit(fn -> detach(test) end)
  end

  @doc """
  Handle a received telemetry event by sending a message to the test process
  """
  def handle_event(event_name, measurements, metadata, pid) do
    send(pid, {:telemetry_event, %{event_name: event_name, measurements: measurements, metadata: metadata}})
  end

  @doc """
  Detach event handler (this is done automatically when test exits)
  """
  def detach(test) do
    :telemetry.detach(test)
  end

  @doc """
  Pull out the name the app used for a db activity (like a query)
  """
  def ecto_event_name(metadata) do
    Instrumenter.ecto_event_name(metadata)
  end
end
