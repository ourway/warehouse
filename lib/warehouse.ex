defmodule Warehouse do
  @moduledoc """
  Documentation for `Warehouse`.
  This calls supervisor, supervisor itself will call Receiver.
  we have just one Receiver which controlls everything else
  """
  use Application

  def start(_type, _args) do
    Warehouse.Supervisor.start_link()
  end
end
