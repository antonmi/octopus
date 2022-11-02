defmodule Octopus.Execution.PostgrexClient.Start do
  alias Octopus.Utils

  def call(%{"args" => args}) do
    sup_pid = Process.whereis(Octopus.DynamicSupervisor)

    process_name = String.to_atom("Elixir.#{Utils.modulize(args["process_name"])}")
    connection = args["connection"]

    case DynamicSupervisor.start_child(
           sup_pid,
           {Postgrex, postgrex_args(connection, process_name)}
         ) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp postgrex_args(connection, process_name) do
    [
      database: connection["database"],
      host: connection["host"],
      password: connection["password"],
      port: connection["port"],
      username: connection["username"],
      name: process_name
    ]
  end
end
