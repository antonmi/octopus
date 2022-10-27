defmodule Octopus.Service do
  alias Octopus.Service.Storage

  @interface_types %{
    "unix_command" => Octopus.Interface.UnixCommand,
    "json_api" => Octopus.Interface.JsonApi
  }

  @execution_types %{
    "process" => Octopus.Execution.Process
  }

  def define(definition) do
    interface_definition = definition["interface"]
    module = Map.fetch!(@interface_types, interface_definition["type"])

    with {:ok, code} <- apply(module, :define, [definition["name"], interface_definition]),
         {:ok, _result} <- run_service(definition["execution"]) do
      Storage.add(definition)
      {:ok, code}
    end
  end

  def run_service(nil), do: {:ok, :nothing_to_run}

  def run_service(execution_definition) do
    module = Map.fetch!(@execution_types, execution_definition["type"])

    case apply(module, :run, [execution_definition]) do
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
