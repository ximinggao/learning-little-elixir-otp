defmodule Pooly.Server do
  use GenServer

  ## API

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def checkout(pool_name) do
    GenServer.call(:"#{pool_name}PoolServer", :checkout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.cast(:"#{pool_name}PoolServer", {:checkin, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(:"#{pool_name}PoolServer", :status)
  end

  ## Callbacks
  def init(args) do
    {:ok, args}
  end
end
