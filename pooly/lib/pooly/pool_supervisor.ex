defmodule Pooly.PoolSupervisor do
  use Supervisor

  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config, name: :"#{pool_config[:name]}PoolSupervisor")
  end

  def init(pool_config) do
    children = [
      {Pooly.PoolServer, pool_config},
      {Pooly.WorkerSupervisor, pool_config[:name]}
    ]

    opts = [strategy: :one_for_all]
    Supervisor.init(children, opts)
  end
end
