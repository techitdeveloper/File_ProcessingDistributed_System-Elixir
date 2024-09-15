defmodule FileProcessor.CsvSourceManager do
  use GenServer, restart: :transient
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: via_tuple())
  end

  def init(_) do
    Logger.info("Started CsvSourceManager on node #{Node.self()}")
    {:ok, []}
  end

  def add_source(url) do
    GenServer.cast(via_tuple(), {:add_source, url})
  end

  def remove_source(url) do
    GenServer.cast(via_tuple(), {:remove_source, url})
  end

  def get_sources do
    GenServer.call(via_tuple(), :get_sources)
  end

  def handle_cast({:add_source, urls}, sources) when is_list(urls) do
    new_sources = Enum.reject(urls, fn url -> url in sources end)

    case new_sources do
      [] ->
        Logger.info("All sources already exist")
        {:noreply, sources}

      _ ->
        Logger.info("Added new CSV sources: #{inspect(new_sources)}")
        {:noreply, new_sources ++ sources}
    end
  end

  def handle_cast({:remove_source, url}, sources) do
    if url in sources do
      Logger.info("Removed CSV source: #{url}")
      {:noreply, List.delete(sources, url)}
    else
      {:noreply, sources}
    end
  end

  def handle_call(:get_sources, _from, sources) do
    {:reply, sources, sources}
  end

  def via_tuple, do: {:via, Horde.Registry, {FileProcessor.Registry, __MODULE__}}
end
