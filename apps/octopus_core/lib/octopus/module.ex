defmodule Octopus.Module do
  @moduledoc """
     Defines a client for defining elixir modules in runtime.
  """

  defmodule Adapter do
    def call(args, configs, state) do
      module = build_module(Map.fetch!(configs, "module"))
      function = String.to_atom(Map.fetch!(configs, "function"))

      {:ok, Octopus.Module.call(module, function, args, state)}
    end

    defp build_module(module_name) do
      String.to_existing_atom("Elixir.#{module_name}")
    end
  end

  def start(args, configs) do
    code = args["code"] || configs["code"]

    case code do
      nil ->
        {:error, "Code is not provided"}

      code when is_binary(code) ->
        eval_code(code)

      code when is_list(code) ->
        code
        |> Enum.join("\n")
        |> eval_code()
    end
  end

  def call(module, function, args, _state) do
    apply(module, function, [args])
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {_value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end
end
