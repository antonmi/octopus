defmodule Octopus.Execution.Compile.Start do
  def call(%{"code" => code}) when is_binary(code) do
    code
    |> namespace_code()
    |> eval_code()
  end

  def call(%{"code" => code}) when is_list(code) do
    code
    |> Enum.join("\n")
    |> namespace_code()
    |> eval_code()
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end

  def namespace_code(code) do
    EEx.eval_string(
      """
        defmodule Octopus.Sandbox do
          <%= code %>
        end
      """,
      code: code
    )
  end
end
