defmodule Octopus.Rpc.UnixCommand do
  alias Octopus.Rpc.UnixCommand.{InputAdapter, Client, OutputAdapter}

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

    with {:ok, input} <- InputAdapter.call(args, config["input"]),
         {:ok, out} <- Client.call(input, config["call"]),
         {:ok, formatted_output} <- OutputAdapter.call(out, config["output"]) do
      {:ok, formatted_output}
    end
  end

  defp template() do
    ".."
    |> Path.expand(__ENV__.file)
    |> Path.join("unix_command")
    |> Path.join("template.eex")
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end
end
