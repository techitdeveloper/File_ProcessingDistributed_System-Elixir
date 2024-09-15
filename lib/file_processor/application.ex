defmodule FileProcessor.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      FileProcessor.Repo,
      {Horde.Registry, name: FileProcessor.Registry, keys: :unique, members: :auto},
      {Horde.DynamicSupervisor,
       name: FileProcessor.DynamicSupervisor,
       strategy: :one_for_one,
       distribution_strategy: Horde.UniformDistribution,
       shutdown: 10_000,
       members: :auto},
      {Cluster.Supervisor, [topologies, [name: FileProcessor.ClusterSupervisor]]},
      FileProcessor.Database,
      {Task.Supervisor, name: FileProcessor.TaskSupervisor},
      FileProcessor.ProcessStarter
    ]

    opts = [strategy: :one_for_one, name: FileProcessor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
