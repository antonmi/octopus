defmodule Octopus.Rpc.JsonApi do
  alias Octopus.Rpc.JsonApi.{Input, Call, Output}

  def define(definition) do
    name = Macro.camelize(definition["name"])

    template()
    |> EEx.eval_file(name: name, interface: definition["interface"])
    |> eval_code()
    |> case do
      {:ok, code} ->
        {:ok, code}
    end
  end

  def call(args, config) do
    config = :erlang.binary_to_term(Base.decode64!(config))

    with {:ok, input} <- Input.call(args, config["input"]),
         {:ok, body} <- Call.call(input, config["call"]),
         {:ok, formatted_output} <- Output.call(body, config["output"]) do
      {:ok, formatted_output}
    end
  end

  defp template() do
    ".."
    |> Path.expand(__ENV__.file)
    |> Path.join("json_api")
    |> Path.join("template.eex")
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end
end
