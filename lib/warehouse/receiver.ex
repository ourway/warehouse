defmodule Warehouse.Receiver do
  use GenServer
  alias Warehouse.Deliverator

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = %{assignments: []}
    {:ok, state}
  end

  def receive_and_chunk(packages) do
    packages |> Enum.chunk_every(10) |> Enum.each(&receive_packages/1)
  end

  def receive_packages(packages) do
    GenServer.cast(__MODULE__, {:receive_packages, packages})
  end

  def handle_cast({:receive_packages, packages}, state) do
    IO.puts("received #{Enum.count(packages)} packages")
    {:ok, delivarator} = Deliverator.start()
    Process.monitor(delivarator)
    state = assign_packages(state, packages, delivarator)
    Deliverator.deliver_packages(delivarator, packages)
    {:noreply, state}
  end

  def assign_packages(state, packages, delivarator) do
    new_assignments = packages |> Enum.map(fn package -> {package, delivarator} end)
    assignments = state.assignments ++ new_assignments
    %{state | assignments: assignments}
  end

  def handle_info({:package_delivered, package}, state) do
    IO.puts("package #{inspect(package)} was delivered")

    delivered_assignments =
      state.assignments
      |> Enum.filter(fn {assign_package, _pid} -> assign_package.id == package.id end)

    assignments = state.assignments -- delivered_assignments
    state = %{state | assignments: assignments}
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, deliverator, :normal}, state) do
    IO.puts("deliverator #{inspect(deliverator)} completed mission")
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, deliverator, reason}, state) do
    IO.puts("deliverator #{inspect(deliverator)} failed: #{inspect(reason)}")
    failed_assignments = filter_by_deliverator(deliverator, state.assignments)
    failed_packages = failed_assignments |> Enum.map(fn {package, _pid} -> package end)
    assignments = state.assignments -- failed_assignments
    state = %{state | assignments: assignments}
    receive_packages(failed_packages)
    {:noreply, state}
  end

  defp filter_by_deliverator(deliverator, assignments) do
    assignments
    |> Enum.filter(fn {_package, assigned_deliverator} ->
      assigned_deliverator == deliverator
    end)
  end
end
