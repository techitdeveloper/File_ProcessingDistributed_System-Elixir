defmodule FileProcessor.Schema.ExchangeRate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exchange_rates" do
    field(:currency, :string)
    field(:rate, :float)

    timestamps()
  end

  def changeset(exchange_rate, attrs) do
    exchange_rate
    |> cast(attrs, [:currency, :rate])
    |> validate_required([:currency, :rate])
    |> unique_constraint(:currency)
  end
end
