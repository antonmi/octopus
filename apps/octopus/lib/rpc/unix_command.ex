defmodule Octopus.Rpc.UnixCommand do
  alias Octopus.Rpc.UnixCommand.{Input, Call, Output}

  def define(definition) do
    service_name = Macro.camelize(definition["name"])
    rpc_module_name = Macro.camelize(definition["type"])

    template()
    |> EEx.eval_file(
      service_name: service_name,
      rpc_module_name: rpc_module_name,
      interface: definition["interface"]
    )
    |> eval_code()
    |> case do
      {:ok, code} ->
        {:ok, code}
    end
  end

  def call(args, config) do
    config = :erlang.binary_to_term(Base.decode64!(config))

    with {:ok, input} <- Input.call(args, config["input"]),
         {:ok, out} <- Call.call(input, config["call"]),
         {:ok, formatted_output} <- Output.call(out, config["output"]) do
      {:ok, formatted_output}
    end
  end

  defp template() do
    "../.."
    |> Path.expand(__ENV__.file)
    |> Path.join("service")
    |> Path.join("template.eex")
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end
end
