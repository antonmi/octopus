defmodule Octopus.Interface.Code.Call do
  def call(input, config) do
    result = do_call(config["module"], config["function"], config["sandbox"], input)
    {:ok, result}
  end

  def do_call(module_name, function_name, use_sandbox_namespace, input) do
    module = build_module(module_name, use_sandbox_namespace)
    function = String.to_atom(function_name)

    case input do
      input when is_list(input) ->
        apply(module, function, input)

      input ->
        apply(module, function, [input])
    end
  end

  defp build_module(module_name, true) do
    String.to_existing_atom("Elixir.Octopus.Sandbox.#{module_name}")
  end

  defp build_module(module_name, false) do
    String.to_existing_atom("Elixir.#{module_name}")
  end
end
