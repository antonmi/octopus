defmodule Octopus.ApiEval do

  alias Octopus.Definition.Storage

  def eval(path, payload) do
    definition = Storage.get_by_request_path(path)
    apply(module_name(definition[:name]), :call, [payload])
  end

  defp module_name(name) do
    name = Macro.camelize(name)
    String.to_existing_atom("Elixir.Octopus.Service.#{name}")
  end
end
