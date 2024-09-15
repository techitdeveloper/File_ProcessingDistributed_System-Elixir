defmodule FileProcessor.CsvFetcher do
  use GenServer, restart: :transient
  require Logger

  @max_retries 3
  @initial_delay 1000

  def start_link(url) do
    GenServer.start_link(__MODULE__, url, name: via_tuple(url))
  end

  def init(url) do
    Process.send(self(), :process_csv, [])
    {:ok, url}
  end

  def handle_info(:process_csv, url) do
    Logger.info("Fetching #{url} on #{Node.self()}")
    download_and_store(url)
    {:stop, :normal, url}
  end

  defp download_and_store(url) do
    download_with_retry(url, @max_retries, @initial_delay)
  end

  defp download_with_retry(url, retries_left, delay) when retries_left > 0 do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        save_to_local_directory(url, body)
        Horde.Registry.unregister(FileProcessor.Registry, url)

      {:error, reason} ->
        Logger.warning(
          "Failed to download CSV from #{url}: #{inspect(reason)}. Retries left: #{retries_left}"
        )

        :timer.sleep(delay)
        download_with_retry(url, retries_left - 1, delay * 2)
    end
  end

  defp download_with_retry(url, 0, _delay) do
    Logger.error("Failed to download CSV from #{url} after all retry attempts")
    Horde.Registry.unregister(FileProcessor.Registry, url)
  end

  defp save_to_local_directory(url, content) do
    filename = "csv_files/" <> Path.basename(url)
    File.mkdir_p!("csv_files")

    case File.write(filename, content) do
      :ok ->
        Logger.info("Successfully saved CSV to #{filename}")

      {:error, reason} ->
        Logger.error("Failed to save CSV to #{filename}: #{inspect(reason)}")
    end
  end

  defp via_tuple(url) do
    {:via, Horde.Registry, {FileProcessor.Registry, url}}
  end
end
