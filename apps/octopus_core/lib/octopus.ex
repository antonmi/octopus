defmodule Octopus do
  alias Octopus.{Configs, Definition, Utils}

  @spec define(map()) :: {:ok, String.t()} | no_return()
  def define(definition) do
    definition
    |> Definition.new()
    |> Definition.define()
  rescue
    error in Octopus.DefinitionError ->
      {:error, error.message}
  end

  @spec start(String.t(), map()) :: {:ok, map()} | no_return()
  def start(service_name, args \\ %{}) when is_binary(service_name) and is_map(args) do
    module = build_module(service_name)
    apply(module, :start, [args])
  rescue
    error ->
      {:error, error.message}
  end

  @spec call(String.t(), String.t(), map()) :: {:ok, map()} | no_return()
  def call(service_name, function_name, args)
      when is_binary(service_name) and is_binary(function_name) and is_map(args) do
    module = build_module(service_name)
    apply(module, String.to_atom(function_name), [args])
  rescue
    error ->
      {:error, error.message}
  end

  defp build_module(service_name) do
    module_name = Utils.modulize(service_name)
    namespace = Configs.services_namespace()
    module = String.to_atom("Elixir.#{namespace}.#{module_name}")

    if Utils.module_exist?(module) do
      module
    else
      raise "Module '#{module}' doesn't exist!"
    end
  end
end