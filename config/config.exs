import Config

config :file_processor, FileProcessor.Repo,
  database: "file_processor_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :file_processor, ecto_repos: [FileProcessor.Repo]

config :libcluster,
  topologies: [
    example_cluster: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45892
      ]
    ]
  ]
