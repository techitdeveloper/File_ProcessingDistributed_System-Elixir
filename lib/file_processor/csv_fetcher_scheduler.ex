defmodule FileProcessor.CsvFetcherScheduler do
  use GenServer, restart: :transient
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{},
      name: {:via, Horde.Registry, {FileProcessor.Registry, __MODULE__}}
    )
  end

  def init(state) do
    Logger.info("Started CsvFetcherScheduler on node #{Node.self()}")
    schedule_download()
    {:ok, state}
  end

  def handle_info(:schedule_downloads, state) do
    schedule_csv_downloads()
    schedule_download()
    {:noreply, state}
  end

  defp schedule_download do
    Process.send_after(self(), :schedule_downloads, :timer.seconds(60))
  end

  defp schedule_csv_downloads do
    # csv_sources = get_csv_sources()
    get_csv_sources()
    csv_sources = FileProcessor.Api.list_csv_sources()
    Enum.each(csv_sources, &schedule_csv_download/1)
  end

  defp schedule_csv_download(url) do
    case Horde.Registry.lookup(FileProcessor.Registry, url) do
      [] ->
        Horde.DynamicSupervisor.start_child(
          FileProcessor.DynamicSupervisor,
          {FileProcessor.CsvFetcher, url}
        )

      [{pid, _}] ->
        Logger.info("#{url} is already being processed by PID #{inspect(pid)}")
    end
  end

  defp get_csv_sources do
    urls = [
      "http://localhost:8000/test1.csv",
      "http://localhost:8000/test2.csv",
      "http://localhost:8000/test3.csv"
      # "http://localhost:8000/test4.csv",
      # "http://localhost:8000/test5.csv",
      # "http://localhost:8000/test6.csv"
    ]

    FileProcessor.Api.add_csv_source(urls)
  end

  # urls = ["http://localhost:8000/test1.csv","http://localhost:8000/test2.csv",
  # "http://localhost:8000/test3.csv","http://localhost:8000/test4.csv","http://localhost:8000/test5.csv",
  # "http://localhost:8000/test6.csv"]
end
