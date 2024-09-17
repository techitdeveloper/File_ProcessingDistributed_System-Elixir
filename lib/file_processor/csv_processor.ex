defmodule FileProcessor.CsvProcessor do
  alias FileProcessor.Database
  use GenServer, restart: :transient
  require Logger

  @max_retries 3
  @initial_delay 1000

  def start_link(file_path) do
    GenServer.start_link(__MODULE__, file_path)
  end

  def init(file_path) do
    Logger.info("Initializing CSV Processor for file: #{file_path}")

    case acquire_lock(file_path) do
      :ok ->
        Process.send(self(), {:process_csv, 0}, [])
        {:ok, file_path}

      :error ->
        Logger.warning("Failed to acquire lock for file: #{file_path}")
        {:stop, :normal}
    end
  end

  def handle_info({:process_csv, retry_count}, file_path) do
    Logger.info("Processing CSV file: #{file_path}, retry count: #{retry_count}")

    case process_csv_file(file_path) do
      :ok ->
        Logger.info("Successfully processed CSV file: #{file_path}")
        delete_file(file_path)
        release_lock(file_path)
        {:stop, :normal, file_path}

      {:error, :corrupted_file} ->
        Logger.error("CSV file is corrupted #{file_path}. Moving to Error Directory")
        move_to_error_directory(file_path)
        release_lock(file_path)
        {:stop, :normal, file_path}

      {:error, reason} ->
        if retry_count < @max_retries do
          Logger.warning(
            "Failed to process CSV file: #{inspect(reason)}. Retrying in #{@initial_delay * (retry_count + 1)}ms"
          )

          Process.send_after(
            self(),
            {:process_csv, retry_count + 1},
            @initial_delay * (retry_count + 1)
          )

          {:noreply, file_path}
        else
          Logger.error(
            "Failed to process CSV file after #{@max_retries} attempts: #{inspect(reason)}"
          )

          Logger.error(
            "Failed to process CSV file after #{@max_retries} attempts: #{file_path}. Reason: #{inspect(reason)}. Moving to error directory."
          )

          move_to_error_directory(file_path)
          release_lock(file_path)
          {:stop, :normal, file_path}
        end
    end
  end

  defp process_csv_file(file_path) do
    Logger.debug("Starting to process CSV file: #{file_path}")

    with {:ok, headers} <- validate_headers(file_path),
         {:ok, data} <- parse_csv(file_path, headers),
         {:ok, _} <- insert_data(data) do
      :ok
    else
      {:error, :invalid_headers} ->
        Logger.error("Invalid headers in CSV file: #{file_path}")
        {:error, :corrupted_file}

      {:error, :parse_error} ->
        Logger.error("Error parsing CSV file: #{file_path}")
        {:error, :corrupted_file}

      # ---------------------------------------------------
      {:error, :row_processing_error} ->
        Logger.error("Error processing row in CSV file: #{file_path}")
        {:error, :corrupted_file}

      # ---------------------------------------------------
      {:error, reason} ->
        Logger.error("Error processing CSV file: #{file_path}. Reason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp validate_headers(file_path) do
    try do
      headers =
        file_path
        |> File.stream!()
        |> CSV.decode!(headers: true)
        |> Enum.take(1)
        |> List.first()
        |> Map.keys()
        |> Enum.map(&String.downcase/1)

      required_columns = ["revenue", "currency", "date"]
      missing_columns = required_columns -- headers
      Logger.warning("missing coulumns: #{inspect(missing_columns)}")
      Logger.warning("headers: #{inspect(headers)}")

      if Enum.empty?(missing_columns) do
        {:ok, headers}
      else
        Logger.error("Missing required columns in CSV: #{inspect(missing_columns)}")
        {:error, :invalid_headers}
      end
    rescue
      e ->
        Logger.error("Error validating headers: #{inspect(e)}")
        {:error, :invalid_headers}
    end
  end

  defp downcase_keys(map) do
    Map.new(map, fn {k, v} -> {String.downcase(k), v} end)
  end

  defp parse_csv(file_path, _headers) do
    try do
      data =
        file_path
        |> File.stream!()
        |> CSV.decode!(headers: true)
        |> Stream.map(&downcase_keys/1)
        |> Enum.map(&process_row/1)

      # |> Enum.reject(&is_nil/1)

      # {:ok, data}

      # ---------------------------------------
      if Enum.any?(data, &is_nil/1) do
        {:error, :row_processing_error}
      else
        {:ok, data}
      end

      # ---------------------------------------
    rescue
      e ->
        Logger.error("Error parsing CSV: #{inspect(e)}")
        {:error, :parse_error}
    end
  end

  defp insert_data(data) do
    case Database.insert_processed_data(data) do
      {:ok, result} ->
        Logger.info("Successfully inserted processed data")
        {:ok, result}

      {:error, :timeout} ->
        Logger.error("Timeout occurred while inserting processed data")
        {:error, :database_timeout}

      {:error, reason} ->
        Logger.error("Failed to insert processed data. Reason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp move_to_error_directory(file_path) do
    error_dir = "error_files"
    File.mkdir_p!(error_dir)
    new_path = Path.join(error_dir, Path.basename(file_path))
    File.rename(file_path, new_path)
    Logger.info("Moved corrupted file to: #{new_path}")
  end

  defp delete_file(file_path) do
    case File.rm(file_path) do
      :ok ->
        Logger.info("Successfully deleted file: #{file_path}")

      {:error, reason} ->
        Logger.error("Failed to delete file: #{file_path}. Reason: #{inspect(reason)}")
    end
  end

  defp acquire_lock(file_path) do
    lock_key = {:csv_lock, file_path}

    case Horde.Registry.register(FileProcessor.Registry, lock_key, :locked) do
      {:ok, _} -> :ok
      {:error, {:already_registered, _}} -> :error
    end
  end

  defp release_lock(file_path) do
    lock_key = {:csv_lock, file_path}
    Horde.Registry.unregister(FileProcessor.Registry, lock_key)
  end

  defp process_row(row) do
    with {:ok, currency} <- Map.fetch(row, "currency"),
         {:ok, revenue} <- Map.fetch(row, "revenue"),
         {:ok, date} <- Map.fetch(row, "date"),
         {revenue_value, _} <- Float.parse(revenue),
         {:ok, exchange_rate} <- get_exchange_rate(currency),
         {:ok, parsed_date} <- Date.from_iso8601(date) do
      %{
        original_revenue: Decimal.new(revenue),
        usd_revenue: Decimal.new("#{revenue_value * exchange_rate}"),
        currency: currency,
        date: parsed_date
      }
    else
      error ->
        Logger.error("Error processing row: #{inspect(row)}, Error: #{inspect(error)}")
        nil
    end
  end

  defp get_exchange_rate(currency) do
    try do
      {:ok, FileProcessor.Database.get_exchange_rate(currency)}
    rescue
      e ->
        Logger.error("Error fetching exchange rate: #{inspect(e)}")
        {:error, :exchange_rate_fetch_failed}
    end
  end
end
