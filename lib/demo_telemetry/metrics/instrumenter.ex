defmodule DemoTelemetry.Metrics.Instrumenter do
  @moduledoc """
  Attach to telemetry events of interest
  """
  use GenServer

  require Logger

  @primary_db_metrics [:demo_telemetry, :primary, :query]
  @replica_db_metrics [:demo_telemetry, :replica, :query]
  @other_metrics [:demo_telemetry, :database, :other_repo, :query]
  @events [@primary_db_metrics, @replica_db_metrics, @other_metrics]

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

  defp do_handle_event(@primary_db_metrics, measurements, metadata, _config) do
    output_db_event_data("PRIMARY DATABASE, event: #{inspect(@primary_db_metrics)}", measurements, metadata)
  end

  defp do_handle_event(@replica_db_metrics, measurements, metadata, _config) do
    output_db_event_data("REPLICA DATABASE, event: #{inspect(@replica_db_metrics)}", measurements, metadata)
  end

  defp do_handle_event(@other_metrics, measurements, metadata, _config) do
    output_db_event_data("OTHER DATABASE, event: #{inspect(@other_metrics)}", measurements, metadata)
  end

  defp do_handle_event(name, _, _, _) do
    Logger.warning("#{@unhandled_event}, #{inspect(name)}")
  end

  defp output_db_event_data(which_db, measurements, metadata) do
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

  defp analyze_db_measurements(measurements) do
    Enum.map(measurements, fn {key, val} ->
      microseconds = System.convert_time_unit(val, :native, :microsecond)
      {key, "#{microseconds}μs"}
    end)
  end

  defp analyze_db_metadata(metadata) do
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
end
