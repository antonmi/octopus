defmodule Octopus.Service do
  alias Octopus.Definition
  alias Octopus.Service.Storage
  alias Octopus.{Configs, Utils}

  def define(definition) do
    with {:ok, code} <- Definition.define(definition["name"], definition["interface"]),
         {:ok, _result} <- run_service(definition["execution"]) do
      {:ok, code}
    end
  end

  def run_service(nil), do: {:ok, :nothing_to_run}

  def run_service(execution_definition) do
    execution_module = execution_module_name(execution_definition["type"])

    case apply(execution_module, :run, [execution_definition]) do
      {:ok, result} ->
        {:ok, result}
    end
  end

  def call(name, function, args) do
    module = service_module_name(name)
    function = String.to_atom(function)
    apply(module, function, [args])
  end

  defp service_module_name(name) do
    name = Utils.modulize(name)
    String.to_existing_atom("Elixir.#{services_namespace()}.#{name}")
  end

  defp execution_module_name(name) do
    name = Utils.modulize(name)
    String.to_existing_atom("Elixir.Octopus.Execution.#{name}")
  end

  defp services_namespace do
    Configs.services_namespace()
  end
end
