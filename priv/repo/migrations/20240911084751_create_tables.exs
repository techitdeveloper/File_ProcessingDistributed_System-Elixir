defmodule FileProcessor.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:exchange_rates) do
      add :currency, :string, null: false
      add :rate, :float, null: false

      timestamps()
    end

    create unique_index(:exchange_rates, [:currency])

    create table(:processed_data) do
      add :original_revenue, :decimal, null: false
      add :usd_revenue, :decimal, null: false
      add :currency, :string, null: false
      add :date, :date, null: false

      timestamps()
    end
  end
end
