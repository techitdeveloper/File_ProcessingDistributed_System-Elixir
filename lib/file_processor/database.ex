defmodule FileProcessor.Database do
  alias FileProcessor.Repo
  alias FileProcessor.Schema.{ExchangeRate, ProcessedData}

  use GenServer
  require Logger

  @timeout 5000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_exchange_rate(currency) do
    try do
      GenServer.call(__MODULE__, {:get_exchange_rate, currency}, @timeout)
    catch
      :exit, {:timeout, _} ->
        Logger.error("Timeout occurred while fetching exchange rate for #{currency}")
        {:error, :timeout}
    end
  end

  def update_exchange_rates(rates) do
    GenServer.cast(__MODULE__, {:update_exchange_rate, rates})
  end

  def insert_processed_data(data_list) do
    try do
      GenServer.call(__MODULE__, {:insert_processed_data, data_list}, @timeout)
    catch
      :exit, {:timeout, _} ->
        Logger.error("Timeout occurred while inserting processed data")
        {:error, :timeout}
    end
  end

  def init(_) do
    Logger.info("Database GenServer initialized")
    {:ok, %{exchange_rates: %{}}}
  end

  def handle_call({:get_exchange_rate, currency}, _from, state) do
    Logger.debug("Fetching exchange rate for #{currency}")

    case Map.get(state.exchange_rates, currency) do
      nil ->
        rate = fetch_exchange_from_db(currency)
        new_state = put_in(state, [:exchange_rates, currency], rate)
        Logger.info("Updated exchange rate for #{currency}: #{rate}")
        {:reply, rate, new_state}

      rate ->
        Logger.debug("Returning cached rate for #{currency}: #{rate}")
        {:reply, rate, state}
    end
  end

  def handle_call({:insert_processed_data, data}, _from, state) do
    Logger.debug("Inserting processed data: #{inspect(data)}")

    result =
      case data do
        data when is_map(data) ->
          insert_single_data(data)

        data when is_list(data) ->
          insert_multiple_data(data)

        _ ->
          Logger.error("Received invalid data format: #{inspect(data)}")
          {:error, :invalid_data_format}
      end

    Logger.info("Processed data insertion result: #{inspect(result)}")
    {:reply, result, state}
  end

  def handle_cast({:update_exchange_rate, rates}, state) do
    Logger.info("Updating exchange rates: #{inspect(rates)}")

    Enum.each(rates, fn {currency, rate} ->
      ExchangeRate.changeset(%ExchangeRate{}, %{currency: currency, rate: rate})
      |> Repo.insert(on_conflict: :replace_all, conflict_target: :currency)
    end)

    {:noreply, %{state | exchange_rates: Map.merge(state.exchange_rates, rates)}}
  end

  defp fetch_exchange_from_db(nil), do: 1.0

  defp fetch_exchange_from_db(currency) do
    case Repo.get_by(ExchangeRate, currency: currency) do
      nil ->
        1.0

      rate ->
        rate.rate
    end
  end

  defp insert_single_data(item) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    data_with_timestamp = Map.merge(item, %{inserted_at: now, updated_at: now})
    Repo.insert_all(ProcessedData, [data_with_timestamp])
  end

  defp insert_multiple_data(data_list) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    data_list_with_timestamps =
      Enum.map(data_list, fn item ->
        Map.merge(item, %{inserted_at: now, updated_at: now})
      end)

    Repo.transaction(fn ->
      Enum.reduce_while(data_list_with_timestamps, {0, []}, fn item, {inserted, errors} ->
        case insert_or_update_data(item) do
          {:ok, _} ->
            {:cont, {inserted + 1, errors}}

          {:error, changeset} ->
            error = format_error(changeset)
            {:cont, {inserted, [error | errors]}}
        end
      end)
    end)
  end

  defp insert_or_update_data(item) do
    case Repo.get_by(ProcessedData,
           date: item.date,
           currency: item.currency,
           original_revenue: item.original_revenue
         ) do
      nil ->
        %ProcessedData{}
        |> ProcessedData.changeset(item)
        |> Repo.insert()

      existing ->
        existing
        |> ProcessedData.changeset(item)
        |> Repo.update()
    end
  end

  defp format_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {key, value} -> "#{key} #{value}" end)
    |> Enum.join(", ")
  end
end
