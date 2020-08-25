defmodule Warehouse.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(Warehouse.Receiver, [])
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
