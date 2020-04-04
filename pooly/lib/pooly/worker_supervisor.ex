defmodule Pooly.WorkerSupervisor do
  use DynamicSupervisor

  ## API
  def start_link(name) do
    DynamicSupervisor.start_link(__MODULE__, [], name: :"#{name}WorkerSupervisor")
  end

  def start_child(pid, worker_spec) do
    DynamicSupervisor.start_child(pid, worker_spec)
  end

  ## Callbacks
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
