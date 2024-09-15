defmodule FileProcessor.Schema.ProcessedData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "processed_data" do
    field(:original_revenue, :decimal)
    field(:usd_revenue, :decimal)
    field(:currency, :string)
    field(:date, :date)

    timestamps()
  end

  def changeset(processed_data, attrs) do
    processed_data
    |> cast(attrs, [:original_revenue, :usd_revenue, :currency, :date])
    |> validate_required([:original_revenue, :usd_revenue, :currency, :date])
    |> validate_number(:original_revenue, greater_than_or_equal_to: 0)
    |> validate_number(:usd_revenue, greater_than_or_equal_to: 0)
    |> unique_constraint([:date, :currency, :original_revenue],
      name: :processed_data_date_currency_original_revenue_index
    )
  end
end
