defmodule LoggerJSON.Formatters.GoogleCloudLoggerTest do
  use Logger.Case, async: false
  use ExUnitProperties
  import LoggerJSON.Formatters.GoogleCloudLogger

  property "builds map that can be encoded and decoded" do
    check all message <- printable_payload(),
              level <- log_level(),
              metadata <- metadata() do
      ts = {{2018, 6, 3}, {16, 28, 30, 50}}
      metadata = metadata ++ [file: "my_file.ex", line: 38, module: Foo, function: :bar]
      log_payload = format_event(level, message, ts, metadata, :all)
      decoded_payload = log_payload |> Jason.encode!() |> Jason.decode!()

      expected_metadata =
        for {key, value} <- LoggerJSON.take_metadata(metadata, :all), into: %{} do
          {to_string(key), value}
        end

      expected_message = IO.iodata_to_binary(message)

      assert %{"jsonPayload" => %{"message" => ^expected_message, "metadata" => ^expected_metadata}} = decoded_payload
    end
  end

  defp printable_payload do
    one_of([
      string(:printable)
    ])
  end

  defp log_level do
    one_of([
      constant(:debug),
      constant(:info),
      constant(:warn),
      constant(:error)
    ])
  end

  defp metadata do
    keyword_of(one_of([integer(), float(), string(:printable), boolean(), nil]))
  end
end
