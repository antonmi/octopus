defmodule Octopus.Interface.Code.Call do
  def call(input, config) do
    result = do_call(config["module"], config["function"], input)
    {:ok, result}
  end

  def do_call(module_name, function_name, input) do
    module = String.to_existing_atom("Elixir.#{module_name}")
    function = String.to_atom(function_name)
    case input do
      input when is_list(input) ->
        apply(module, function, input)
      input ->
        apply(module, function, [input])
    end
  end
end
