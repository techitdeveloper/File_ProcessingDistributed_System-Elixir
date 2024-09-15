defmodule FileProcessor.Api do
  def add_csv_source() do
    {:error, :input_error}
  end

  def add_csv_source(url) when is_binary(url) and byte_size(url) > 0 do
    case validate_url(url) do
      :ok -> FileProcessor.CsvSourceManager.add_source([url])
      error -> error
    end
  end

  def add_csv_source(urls) when is_list(urls) do
    case Enum.reduce_while(urls, [], &validate_and_collect_url/2) do
      {:error, reason} -> {:error, reason}
      valid_urls -> FileProcessor.CsvSourceManager.add_source(valid_urls)
    end
  end

  def add_csv_source([]), do: {:error, :empty_list}

  def add_csv_source(_), do: {:error, :invalid_input}

  defp validate_and_collect_url(url, acc) do
    case validate_url(url) do
      :ok -> {:cont, [url | acc]}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp validate_url(url) when is_binary(url) and byte_size(url) > 0 do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when not is_nil(scheme) and not is_nil(host) -> :ok
      _ -> {:error, :invalid_url}
    end
  end

  defp validate_url(_), do: {:error, :invalid_input}

  def remove_csv_source(url) when is_binary(url) and byte_size(url) > 0 do
    FileProcessor.CsvSourceManager.remove_source(url)
  end

  def remove_csv_source(_), do: {:error, :invalid_input}

  def list_csv_sources do
    FileProcessor.CsvSourceManager.get_sources()
  end
end
