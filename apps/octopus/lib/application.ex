defmodule Octopus.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Octopus.DynamicSupervisor},
      {Finch, name: Octopus.Finch}
    ]

    opts = [name: Octopus.Supervisor, strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
