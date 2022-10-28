defmodule Octopus.Service do
  alias Octopus.Definition
  alias Octopus.Service.Storage
  alias Octopus.Utils

  @execution_types %{
    "process" => Octopus.Execution.Process,
    "compile" => Octopus.Execution.Compile
  }

  def define(definition) do
    with {:ok, code} <- Definition.define(definition["name"], definition["interface"]),
         {:ok, _result} <- run_service(definition["execution"]) do
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
    module = module_name(name)
    function = String.to_atom(function)
    apply(module, function, [args])
  end

  defp module_name(name) do
    name = Utils.modulize(name)
    String.to_existing_atom("Elixir.Octopus.Service.#{name}")
  end
end
