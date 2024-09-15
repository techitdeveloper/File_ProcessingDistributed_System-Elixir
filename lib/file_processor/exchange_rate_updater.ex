defmodule FileProcessor.ExchangeRateUpdater do
  alias FileProcessor.Database
  use GenServer, restart: :transient
  require Logger

  @max_retries 3
  @initial_delay 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{},
      name: {:via, Horde.Registry, {FileProcessor.Registry, __MODULE__}}
    )
  end

  def init(state) do
    Logger.info("Started ExchangeRateUpdater on node #{Node.self()}")
    schedule_update()
    {:ok, state}
  end

  def handle_info(:update_exchange_rates, state) do
    Logger.info("Starting exchange rate update cycle")
    update_exchange_rates()
    schedule_update()
    {:noreply, state}
  end

  defp schedule_update do
    Process.send_after(self(), :update_exchange_rates, :timer.seconds(65))
  end

  defp update_exchange_rates do
    Logger.debug("Fetching exchange rates")
    fetch_exchange_rates_with_retry(@max_retries, @initial_delay)
  end

  defp fetch_exchange_rates_with_retry(retries_left, delay) when retries_left > 0 do
    case fetch_exchange_rates() do
      {:ok, exchange_rates} ->
        Logger.info("Successfully fetched exchange rates: #{inspect(exchange_rates)}")
        Database.update_exchange_rates(exchange_rates)
        Logger.info("Updated exchange rates")

      {:error, reason} ->
        Logger.warning(
          "Failed to fetch exchange rates: #{inspect(reason)}. Retries left: #{retries_left}"
        )

        :timer.sleep(delay)
        fetch_exchange_rates_with_retry(retries_left - 1, delay * 2)
    end
  end

  defp fetch_exchange_rates_with_retry(0, _delay) do
    Logger.error("Failed to fetch exchange rates after all retry attempts")
  end

  defp fetch_exchange_rates do
    case :rand.uniform(10) do
      10 ->
        Logger.warning("API failure in fetch_exchange_rates")
        {:error, "API failure"}

      _ ->
        {:ok,
         %{
           "USD" => 1.0,
           "EUR" => 1.18,
           "JPY" => 0.0091,
           "GBP" => 1.38,
           "CAD" => 0.75,
           "AUD" => 0.67,
           "CHF" => 0.94,
           "NOK" => 0.10
         }}
    end
  end
end
