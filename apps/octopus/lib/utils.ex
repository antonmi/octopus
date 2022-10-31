defmodule Octopus.Utils do
  def modulize(string) do
    string
    |> String.split(".")
    |> Enum.map(&Macro.camelize/1)
    |> Enum.join(".")
  end

  def eval_template(template, args, false) do
    {:ok, EEx.eval_string(template, args: args)}
  end

  def eval_template(template, args, true) do
    evaluated_template = EEx.eval_string(template, args: args)
    eval_code(evaluated_template)
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    {:ok, value}
  end
end
