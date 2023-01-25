defmodule OctopusClientPostgrex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: OctopusClientPostgrex.DynamicSupervisor}
    ]

    opts = [strategy: :one_for_one, name: OctopusClientPostgrex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
