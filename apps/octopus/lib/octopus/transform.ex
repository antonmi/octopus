defmodule Octopus.Transform do
  @moduledoc """
  Transforms the arguments according to the given configuration in "prepare" and "transform".
  """
  alias Octopus.CallError
  alias Octopus.Eval

  def transform(args, config, helpers \\ [], context \\ :undefined)

  def transform(args, false, _helpers, _context) do
    {:ok, args}
  end

  def transform(args, config, helpers, context) do
    {:ok, travers_args(args, config, helpers)}
  rescue
    error ->
      {:error,
       %CallError{
         step: context,
         error: error,
         message: Exception.message(error),
         stacktrace: Exception.format_stacktrace(__STACKTRACE__)
       }}
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
    if String.contains?(value, "args") do
      Eval.eval_string(value, args: args, helpers: helpers)
    else
      value
    end
  end

  defp parse_value(value, _args, _helpers), do: value
end
