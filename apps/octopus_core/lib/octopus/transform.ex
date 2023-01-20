defmodule Octopus.Transform do
  alias Octopus.Eval

  def transform(args, config, helpers \\ [])

  def transform(args, false, _helpers) do
    {:ok, args}
  end

  def transform(args, config, helpers) do
    {:ok, travers_args(args, config, helpers)}
  end

  defp travers_args(args, config, helpers) do
    config
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, key, parse_value(value, args, helpers))
    end)
  end

  defp parse_value(value, args, helpers) when is_map(value) do
    value
    |> Enum.reduce(%{}, fn {key, val}, acc ->
      Map.put(acc, key, parse_value(val, args, helpers))
    end)
  end

  defp parse_value(value, args, helpers) when is_list(value) do
    Enum.map(value, fn val ->
      parse_value(val, args, helpers)
    end)
  end

  defp parse_value(value, args, helpers) when is_binary(value) do
    Eval.eval_string(value, args: args, helpers: helpers)
  end

  defp parse_value(value, _args, _helpers), do: value
end
