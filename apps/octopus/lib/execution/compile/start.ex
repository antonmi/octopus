defmodule Octopus.Execution.Compile.Start do
  def call(%{"code" => code}) do
    eval_code(code)
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end
end
