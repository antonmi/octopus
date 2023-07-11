defmodule Octopus.Lambda do
  @moduledoc """
     A client for defining elixir modules in runtime.
  """

  alias Octopus.Utils

  @spec start(map(), map(), map()) :: {:ok, String.t()} | no_return()
  def start(args, configs, _service_name) do
    code = args["code"] || configs["code"]
    module = args["module"] || configs["module"]

    case {code, module} do
      {nil, nil} ->
        {:error, "Ether \"code\" or \"module\" must be provided"}

      {code, nil} when is_binary(code) ->
        eval_code(code)

      {code, nil} when is_list(code) ->
        code
        |> Enum.join("\n")
        |> eval_code()

      {nil, module} ->
        module = build_module(module)
        if Utils.module_exist?(module) do
          {:ok, module}
        else
          {:error, "There is no such module: \"#{module}\"!"}
        end

      {_code, _module} ->
        {:error, "Ether \"code\" or \"module\" must be provided"}
    end
  end

  @spec call(map(), map(), any()) :: {:ok, map()} | no_return()
  def call(args, configs, code) when is_binary(code) do
    module = build_module(Map.fetch!(configs, "module"))
    function = String.to_atom(Map.fetch!(configs, "function"))

    {:ok, apply(module, function, [args])}
  end

  @spec call(map(), map(), any()) :: {:ok, map()} | no_return()
  def call(args, configs, module) when is_atom(module) do
    function = String.to_atom(Map.fetch!(configs, "function"))

    {:ok, apply(module, function, [args])}
  end

  def stop(_args, _configs, _state) do
    :ok
  end

  defp build_module(module_name) do
    if String.starts_with?(module_name, "Elixir.") do
      module_name
    else
      String.to_atom("Elixir.#{module_name}")
    end
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {_value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end
end
