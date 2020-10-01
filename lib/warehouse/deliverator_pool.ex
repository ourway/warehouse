defmodule Warehouse.DeliveratorPool do
  use GenServer
  alias Warehouse.{Deliverator}
  @max 20

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = %{
      deliverators: [],
      max: @max
    }

    {:ok, state}
  end

  def available_deliverator do
    GenServer.call(__MODULE__, {:fetch_available_deliverator})
  end

  def flag_deliverator_busy(deliverator) do
    GenServer.call(__MODULE__, {:flag_deliverator, :busy, deliverator})
  end

  def flag_deliverator_idle(deliverator) do
    GenServer.call(__MODULE__, {:flag_deliverator, :idle, deliverator})
  end

  def remove_deliverator(deliverator) do
    GenServer.call(__MODULE__, {:remove_deliverator, deliverator})
  end

  def handle_call({:fetch_available_deliverator}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:flag_deliverator, flag, deliverator}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:remove_deliverator, deliverator}, _from, state) do
    {:reply, :ok, state}
  end
end
