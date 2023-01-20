defmodule Api.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Api.Router, options: [port: port()]}
    ]

    opts = [strategy: :one_for_one, name: Api.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port() do
    (System.get_env("PORT") || "4002")
    |> String.to_integer()
  end
end
