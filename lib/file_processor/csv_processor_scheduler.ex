defmodule FileProcessor.CsvProcessorScheduler do
  use GenServer, restart: :transient
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{},
      name: {:via, Horde.Registry, {FileProcessor.Registry, __MODULE__}}
    )
  end

  def init(state) do
    Logger.info("Started CsvProcessorScheduler on node #{Node.self()}")
    schedule_processing()
    {:ok, state}
  end

  def handle_info(:process_csvs, state) do
    Logger.info("Starting CSV processing cycle")
    process_csv_files()
    schedule_processing()
    {:noreply, state}
  end

  defp schedule_processing do
    Process.send_after(self(), :process_csvs, :timer.seconds(70))
  end

  defp process_csv_files do
    files = Path.wildcard("csv_files/*.csv")
    Logger.info("Found #{length(files)} CSV files to process")
    Enum.each(files, &start_csv_processor/1)
  end

  defp start_csv_processor(file_path) do
    Horde.DynamicSupervisor.start_child(
      FileProcessor.DynamicSupervisor,
      {FileProcessor.CsvProcessor, file_path}
    )
  end
end
