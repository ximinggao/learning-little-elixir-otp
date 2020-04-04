defmodule Pooly.PoolsSupervisor do
  use Supervisor

  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def init(pools_config) do
    children =
      pools_config
      |> Enum.map(fn pool_config ->
        id = :"#{pool_config[:name]}PoolSupervisor"
        Supervisor.child_spec({Pooly.PoolSupervisor, pool_config}, id: id)
      end)

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
