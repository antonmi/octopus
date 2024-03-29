defmodule Octopus.ElixirModuleClient do
  @moduledoc """
     A client for defining elixir modules in runtime.
  """

  @spec start(map(), map(), map()) :: {:ok, String.t()} | no_return()
  def start(args, configs, _service_name) do
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

  @spec call(map(), map(), any()) :: {:ok, map()} | no_return()
  def call(args, configs, _state) do
    module = build_module(Map.fetch!(configs, "module"))
    function = String.to_atom(Map.fetch!(configs, "function"))

    {:ok, apply(module, function, [args])}
  end

  def stop(_args, _configs, _state) do
    :ok
  end

  defp build_module(module_name) do
    String.to_existing_atom("Elixir.#{module_name}")
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {_value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end
end
