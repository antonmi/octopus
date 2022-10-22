defmodule Octopus.Definition do
  alias Octopus.Definition.Storage

  def define(%{type: "cli", name: name, command: command} = definition) do
    name = Macro.camelize(name)

    "cli.eex"
    |> template()
    |> EEx.eval_file(name: name, command: command)
    |> eval_code()
    |> case do
      {:ok, code} ->
        Storage.add(definition)
        {:ok, code}
    end
  end

  def define(%{type: "json_api", name: name, method: method, url: url} = definition) do
    name = Macro.camelize(name)

    method =
      case method do
        "GET" -> :get
        "POST" -> :post
      end

    "json_api.eex"
    |> template()
    |> EEx.eval_file(name: name, url: url, method: method)
    |> eval_code()
    |> case do
      {:ok, code} ->
        Storage.add(definition)
        {:ok, code}
    end
  end

  def define(%{type: "code", name: name, code: code} = definition) do
    name = Macro.camelize(name)

    "code.eex"
    |> template()
    |> EEx.eval_file(name: name, code: code)
    |> eval_code()
    |> case do
      {:ok, code} ->
        Storage.add(definition)
        {:ok, code}
    end
  end

  defp template(file) do
    ".."
    |> Path.expand(__ENV__.file)
    |> Path.join("templates/executors")
    |> Path.join(file)
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    {:ok, format_code(code)}
  end

  defp format_code(code) do
    code
    |> Code.format_string!(line_length: 80)
    |> Enum.join()
  end
end
