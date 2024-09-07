defmodule DemoTelemetry.Metrics.Instrumenter do
  @moduledoc """
  Attach to telemetry events of interest
  """
  use GenServer

  require Logger

  @transaction_queries ["begin", "commit", "rollback"]
  @primary_db_metrics [:demo_telemetry, :primary, :query]
  @replica_db_metrics [:demo_telemetry, :replica, :query]
  @other_metrics [:demo_telemetry, :database, :other_repo, :query]
  @telemetry_event [:demo_telemetry, :test_telemetry_event]
  @events [@primary_db_metrics, @replica_db_metrics, @other_metrics, @telemetry_event]

  @telemetry_handling_error "Exception thrown when handling error"
  @unhandled_event "Unhandled event name received"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  @impl true
  def init(state) do
    :telemetry.attach_many(__MODULE__, @events, &__MODULE__.handle_event/4, nil)
    {:ok, state}
  end

  def handle_event(event_name, measurements, metadata, config) do
    do_handle_event(event_name, measurements, metadata, config)
  rescue
    e ->
      Logger.warning("#{@telemetry_handling_error}. #{inspect(e)}")
  end

  @doc """
  Look at the telemetry metadata and extract the Ecto event name (if present)
  or return nil

  This handles the transaction related operations (which cannot be named by the
  app).
  """
  @spec ecto_event_name(map()) :: String.t() | nil
  def ecto_event_name(metadata) when is_map(metadata) do
    metadata
    |> get_in([:options, :name])
    |> case do
      nil -> ecto_transaction_name(metadata[:query])
      val -> val
    end
  end

  defp ecto_transaction_name(name) when name in @transaction_queries, do: name
  defp ecto_transaction_name(_), do: nil

  defp do_handle_event(@primary_db_metrics, measurements, metadata, _config) do
    output_db_event_data("PRIMARY DATABASE, event: #{inspect(@primary_db_metrics)}", measurements, metadata)
  end

  defp do_handle_event(@replica_db_metrics, measurements, metadata, _config) do
    output_db_event_data("REPLICA DATABASE, event: #{inspect(@replica_db_metrics)}", measurements, metadata)
  end

  defp do_handle_event(@other_metrics, measurements, metadata, _config) do
    output_db_event_data("OTHER DATABASE, event: #{inspect(@other_metrics)}", measurements, metadata)
  end

  defp do_handle_event(@telemetry_event, measurements, metadata, _config) do
    output_db_event_data("TELEMETRY EVENT, event: #{inspect(@telemetry_event)}", measurements, metadata)
  end

  defp do_handle_event(name, _, _, _) do
    Logger.warning("#{@unhandled_event}, #{inspect(name)}")
  end

  def output_db_event_data(which_db, measurements, metadata) do
    if log_telemetry_info() do
      measurements_info = analyze_db_measurements(measurements)
      metadata_info = analyze_db_metadata(metadata)

      write_info("#{which_db}", underline: true)
      write_info("MEASUREMENTS", underline: true, column: 5)

      Enum.each(measurements_info, fn {k, v} ->
        write_info("* #{k}: #{inspect(v)}", column: 5, color: :light_cyan)
      end)

      write_info("METADATA", underline: true, column: 5)

      Enum.each(metadata_info, fn {k, v} ->
        write_info("* #{k}: #{inspect(v)}", column: 5, color: :light_cyan)
      end)
    end
  end

  def analyze_db_measurements(measurements) do
    Enum.map(measurements, fn {key, val} ->
      microseconds = System.convert_time_unit(val, :native, :microsecond)
      {key, "#{microseconds}μs"}
    end)
  end

  def analyze_db_metadata(metadata) do
    Map.to_list(metadata)
  end

  defp write_info(text, opts) do
    opts |> Keyword.get(:column) |> right()
    opts |> Keyword.get(:underline) |> underline()
    opts |> Keyword.get(:color) |> write_text(text)
    reset()
  end

  defp underline(true) do
    IO.write(IO.ANSI.underline())
  end

  defp underline(_), do: :ok

  defp reset do
    IO.write(IO.ANSI.reset())
  end

  defp right(column) do
    if is_integer(column) do
      IO.write(IO.ANSI.cursor_right(column))
    end
  end

  defp write_text(nil, text), do: IO.puts(text)

  defp write_text(color, text) do
    [color, text] |> IO.ANSI.format() |> IO.puts()
  end

  defp log_telemetry_info do
    Application.get_env(:demo_telemetry, :log_telemetry_info, true)
  end
end
