defmodule Pooly.PoolServer do
  use GenServer

  defmodule State do
    defstruct size: nil, monitors: nil, worker_spec: nil, workers: nil, name: nil, count: 0
  end

  ## API

  def start_link(pool_config) do
    GenServer.start_link(__MODULE__, pool_config, name: :"#{pool_config[:name]}PoolServer")
  end

  def checkout(pool_name) do
    GenServer.call(:"#{pool_name}Server", :checkout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.call(:"#{pool_name}Server", {:checkin, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(:"#{pool_name}Server", :status)
  end

  ## Callbacks

  def init(pool_config) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])

    {:ok,
     %State{
       name: pool_config[:name],
       size: pool_config[:size],
       monitors: monitors,
       worker_spec: pool_config[:worker_spec],
       workers: []
     }}
  end

  def handle_info({:DOWN, ref, _, _}, %{workers: workers, monitors: monitors} = state) do
    case :ets.match(monitors, {"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [pid | workers]}
        {:noreply, new_state}

      [[]] ->
        {:noreply, state}
    end
  end

  def handle_info(
        {:EXIT, pid, _reason},
        %{
          monitors: monitors,
          workers: workers,
          count: count
        } = state
      ) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: workers -- [pid], count: count - 1}
        {:noreply, new_state}

      [[]] ->
        {:noreply, state}
    end
  end

  def handle_call(
        :checkout,
        {from_pid, _ref},
        %{
          name: name,
          size: size,
          worker_spec: worker_spec,
          workers: workers,
          monitors: monitors,
          count: count
        } = state
      ) do
    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] when size > count ->
        {:ok, worker} =
          Pooly.WorkerSupervisor.start_child(
            :"#{name}WorkerSupervisor",
            Supervisor.child_spec(worker_spec, restart: :temporary)
          )

        Process.link(worker)
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | count: count + 1}}

      _ ->
        {:reply, :noproc, state}
    end
  end

  def handle_call(
        :status,
        _from,
        %{size: size, count: count, workers: workers, monitors: monitors} = state
      ) do
    {:reply,
     %{
       size: size,
       count: count,
       idle: length(workers),
       checked_out: :ets.info(monitors, :size)
     }, state}
  end

  def handle_cast({:checkin, worker}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [pid | workers]}}

      [] ->
        {:noreply, state}
    end
  end

  ## Private Functions
end
