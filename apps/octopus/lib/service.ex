defmodule Octopus.Service do
  alias Octopus.Service.Storage

  @types %{
    "unix_command" => Octopus.Rpc.UnixCommand,
    "json_api" => Octopus.Rpc.JsonApi
  }

  @run_types %{
    "process" => Octopus.Run.Process
  }

  def define(definition) do
    module = Map.fetch!(@types, definition["type"])

    with {:ok, code} <- apply(module, :define, [definition]),
         {:ok, _result} <- run_service(definition["run"]) do
      Storage.add(definition)
      {:ok, code}
    end
  end

  def run_service(nil), do: {:ok, :nothing_to_run}

  def run_service(run_definition) do
    module = Map.fetch!(@run_types, run_definition["type"])

    case apply(module, :run, [run_definition]) do
      {:ok, result} ->
        {:ok, result}
    end
  end

  def call(name, function, args) do
    definition = Storage.get(name)
    module = module_name(definition["name"])
    function = String.to_atom(function)
    apply(module, function, [args])
  end

  defp module_name(name) do
    name = Macro.camelize(name)
    String.to_existing_atom("Elixir.Octopus.Service.#{name}")
  end
end
