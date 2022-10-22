defmodule Api.Definition do
  def define(params) do
    args = atomize_keys(params)

    case Octopus.Definition.define(args) do
      {:ok, code} ->
        {:ok, code}
    end
  end

  defp atomize_keys(nil), do: nil

  defp atomize_keys(map = %{}) do
    map
    |> Enum.map(fn {key, value} -> {String.to_atom(key), atomize_keys(value)} end)
    |> Enum.into(%{})
  end

  defp atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  defp atomize_keys(not_a_map) do
    not_a_map
  end
end
