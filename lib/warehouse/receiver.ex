defmodule Warehouse.Receiver do
  use GenServer
  alias Warehouse.Deliverator

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def receive_and_chunk(packages) do
    packages |> Enum.chunk_every(10) |> Enum.each(&receive_packages/1)
  end

  def receive_packages(packages) do
    GenServer.cast(__MODULE__, {:receive_packages, packages})
  end

  @impl true
  def init(_) do
    state = %{assignments: []}
    {:ok, state}
  end

  @impl true
  def handle_cast({:receive_packages, packages}, state) do
    IO.puts("received #{Enum.count(packages)} packages")
    ## start the process
    {:ok, delivarator} = Deliverator.start()
    ## monitor it's messages
    Process.monitor(delivarator)
    ## Add new packages to state
    state = assign_packages(state, packages, delivarator)
    ## Run the endpoint function
    Deliverator.deliver_packages(delivarator, packages)
    ## update the state
    {:noreply, state}
  end

  @impl true
  def handle_info({:package_delivered, package}, state) do
    IO.puts("package #{inspect(package)} was delivered")

    delivered_assignments =
      state.assignments
      |> Enum.filter(fn {assign_package, _pid} -> assign_package.id == package.id end)

    assignments = state.assignments -- delivered_assignments
    state = %{state | assignments: assignments}
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, deliverator, :normal}, state) do
    IO.puts("deliverator #{inspect(deliverator)} completed mission")
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, deliverator, reason}, state) do
    IO.puts("deliverator #{inspect(deliverator)} failed: #{inspect(reason)}")
    failed_assignments = filter_by_deliverator(deliverator, state.assignments)
    failed_packages = failed_assignments |> Enum.map(fn {package, _pid} -> package end)
    assignments = state.assignments -- failed_assignments
    state = %{state | assignments: assignments}
    receive_packages(failed_packages)
    {:noreply, state}
  end

  @doc "return a new state with new assignments"
  def assign_packages(state, packages, delivarator) do
    ## add deliverator pid to packages
    new_assignments = packages |> Enum.map(fn package -> {package, delivarator} end)
    ## add new assignments to old ones
    assignments = state.assignments ++ new_assignments
    ## return the satate
    %{state | assignments: assignments}
  end

  defp filter_by_deliverator(deliverator, assignments) do
    assignments
    |> Enum.filter(fn {_package, assigned_deliverator} ->
      assigned_deliverator == deliverator
    end)
  end
end
