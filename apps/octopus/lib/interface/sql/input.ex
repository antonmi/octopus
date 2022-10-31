defmodule Octopus.Interface.Sql.Input do
  alias Octopus.Utils

  def call(args, %{
        "transform" => %{"template" => template, "eval" => eval},
        "args" => args_config
      }) do
    evaluated_template = EEx.eval_string(template, args: args)

    if eval do
      eval_code(evaluated_template)
    else
      {:ok, evaluated_template}
    end
  end

  def call(args, %{"args" => %{}}) do
    {:ok, []}
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    {:ok, value}
  end
end
