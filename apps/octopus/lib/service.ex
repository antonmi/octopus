defmodule Octopus.Service do
  alias Octopus.Definition.Storage

  @types %{
    "unix_command" => Octopus.Rpc.UnixCommand
  }

  def define(definition) do
    module = Map.fetch!(@types, definition["type"])

    case apply(module, :define, [definition]) do
      {:ok, code} ->
        Storage.add(definition)
        {:ok, code}
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
