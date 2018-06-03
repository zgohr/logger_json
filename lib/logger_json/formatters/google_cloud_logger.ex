defmodule LoggerJSON.Formatters.GoogleCloudLogger do
  @moduledoc """
  Google Cloud Logger formatter.

  It uses Jason.Helpers.json_map
  """
  import Jason.Helpers, only: [json_map: 1]

  @behaviour LoggerJSON.Formatter

  @doc """
  Builds a map that corresponds to Google Cloud Logger
  [`LogEntry`](https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry) format.
  """
  def format_event(level, msg, ts, md, md_keys) do
    json_map(
      timestamp: format_timestamp(ts),
      severity: format_severity(level),
      jsonPayload: json_map(
        message: IO.iodata_to_binary(msg),
        metadata: format_metadata(md, md_keys)
      ),
      resource: format_resource(md),
      sourceLocation: format_source_location(md)
    )
  end

  defp format_resource(md) do
    application = Keyword.get(md, :application)

    if application do
      json_map(
        type: "elixir-application",
        labels: json_map(
          service: application,
          version: ["\"", Application.spec(application, :vsn), "\""] |> Jason.Fragment.new()
        )
      )
    end
  end

  defp format_metadata(md, md_keys) do
    md
    |> Keyword.drop([:pid, :file, :line, :function, :module, :ansi_color])
    |> LoggerJSON.take_metadata(md_keys)
  end

  # RFC3339 UTC "Zulu" format
  defp format_timestamp({date, time}) do
    ["\"", format_date(date), ?T, format_time(time), ?Z, "\""]
    |> Jason.Fragment.new()
  end

  # Description can be found in Google Cloud Logger docs;
  # https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#LogEntrySourceLocation
  defp format_source_location(metadata) do
    file = Keyword.get(metadata, :file)
    line = Keyword.get(metadata, :line)
    function = Keyword.get(metadata, :function)
    module = Keyword.get(metadata, :module)

    json_map(
      file: file,
      line: line,
      function: format_function(module, function)
    )
  end

  defp format_function(nil, function) do
    to_string(function)
  end

  defp format_function(module, function) do
    ["\"", to_string(module), ".", to_string(function), "\""] |> Jason.Fragment.new()
  end

  # Severity levels can be found in Google Cloud Logger docs:
  # https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#LogSeverity
  defp format_severity(:debug), do: "DEBUG"
  defp format_severity(:info), do: "INFO"
  defp format_severity(:warn), do: "WARNING"
  defp format_severity(:error), do: "ERROR"
  defp format_severity(nil), do: "DEFAULT"

  defp format_time({hh, mi, ss, ms}) do
    [pad2(hh), ":", pad2(mi), ":", pad2(ss), ".", pad3(ms)]
  end

  defp format_date({yy, mm, dd}) do
    [Integer.to_string(yy), "-", pad2(mm), "-", pad2(dd)]
  end

  defp pad3(int) when int < 10, do: [?0, ?0, Integer.to_string(int)]
  defp pad3(int) when int < 100, do: [?0, Integer.to_string(int)]
  defp pad3(int), do: Integer.to_string(int)

  defp pad2(int) when int < 10, do: [?0, Integer.to_string(int)]
  defp pad2(int), do: Integer.to_string(int)
end
