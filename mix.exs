defmodule FileProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :file_processor,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {FileProcessor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # To make HTTP requests to fetch CSV files
      {:httpoison, "~> 1.8"},
      # To parse CSV files
      {:csv, "~> 2.4"},
      # To handle scheduling based on time
      {:timex, "~> 3.7"},
      {:horde, "~> 0.8.3"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:libcluster, "~> 3.3"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
