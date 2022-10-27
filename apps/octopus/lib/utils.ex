defmodule Octopus.Utils do
  def eval_pattern(string, args) do
    ~r{:(\w+\b)}
    |> Regex.scan(string)
    |> Enum.reduce(string, fn [colon_arg, arg], acc ->
      value = Map.fetch!(args, arg)
      String.replace(acc, colon_arg, "#{value}")
    end)
  end
end
