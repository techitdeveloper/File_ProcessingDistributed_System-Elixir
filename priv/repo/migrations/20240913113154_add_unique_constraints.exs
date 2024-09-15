defmodule FileProcessor.Repo.Migrations.AddUniqueConstraints do
  use Ecto.Migration

  def change do
    create unique_index(:processed_data, [:date, :currency, :original_revenue])
  end
end
