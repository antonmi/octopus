defmodule OctopusAgent.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: OctopusAgent.Router, options: [port: port()]}
    ]

    opts = [strategy: :one_for_one, name: OctopusAgent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port() do
    (System.get_env("PORT") || "4001")
    |> String.to_integer()
  end
end
