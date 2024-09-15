defmodule FileProcessor.ProcessStarter do
  use GenServer
  require Logger

  @distributed_processes [
    FileProcessor.CsvSourceManager,
    FileProcessor.CsvFetcherScheduler,
    FileProcessor.CsvProcessorScheduler,
    FileProcessor.ExchangeRateUpdater
  ]

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    :net_kernel.monitor_nodes(true)
    Process.send_after(self(), :start_processes, 5000)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:start_processes, state) do
    Enum.each(@distributed_processes, &start_horde_child/1)
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    Logger.warning("Node #{node} went down. Redistributing processes.")
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    Logger.info("Node #{node} came up. Rebalancing processes may occur.")
    {:noreply, state}
  end

  defp start_horde_child(module) do
    Logger.info("Attempting to start #{inspect(module)}")

    case Horde.DynamicSupervisor.start_child(
           FileProcessor.DynamicSupervisor,
           module
         ) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        :ok

      {:error, _reason} = error ->
        Logger.warning("Failed to start #{inspect(module)}: #{inspect(error)}")
        error
    end
  end
end
