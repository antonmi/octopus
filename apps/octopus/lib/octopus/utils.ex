defmodule Octopus.Utils do
  @moduledoc false

  def modulize(string) do
    string
    |> String.replace("-", "_")
    |> String.split(".")
    |> Enum.map(&Macro.camelize/1)
    |> Enum.join(".")
  end

  def eval_template(template, args, false) do
    eval_eex_template(template, args: args)
  end

  def eval_template(template, args, true) do
    evaluated_template = eval_eex_template(template, args: args)
    eval_code(evaluated_template)
  end

  def module_exist?(module) do
    case Code.ensure_compiled(module) do
      {:module, ^module} ->
        true

      {:error, _} ->
        false
    end
  end

  defp eval_eex_template(template, args: args) when is_binary(template) do
    EEx.eval_string(template, args: args)
  end

  defp eval_eex_template(template, args: args) when is_list(template) do
    template
    |> Enum.join()
    |> EEx.eval_string(args: args)
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    value
  end
end
