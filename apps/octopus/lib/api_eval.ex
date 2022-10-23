defmodule Octopus.ApiEval do
  alias Octopus.Definition.Storage

  def eval(name, function, args) do
    definition = Storage.get(name)
    module = module_name(definition[:name])
    function = String.to_atom(function)
    apply(module, function, [args])
  end

  defp module_name(name) do
    name = Macro.camelize(name)
    String.to_existing_atom("Elixir.Octopus.Service.#{name}")
  end
end
