defmodule Hermod.Supervisor do
  use Supervisor

  def start_link do
    {:ok, _sup} = Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(Hermod.RedisHandler, [])
    ]

    supervise(children, [strategy: :one_for_one])
  end

end

