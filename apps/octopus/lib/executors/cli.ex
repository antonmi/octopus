defmodule Octopus.Executors.Cli do
  def call(command, args, config) do
    config = :erlang.binary_to_term(Base.decode64!(config))

    args = build_args(config[:input], args)

    case do_call_command(command, args) do
      {:ok, out} ->
        {:ok, prepare_output(out)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp build_args(%{transform: transform}, args) when is_binary(transform) do
    Regex.scan(~r{:(\w+\b)}, transform)
    |> Enum.reduce(transform, fn [colon_arg, arg], acc ->
      value = Map.get(args, arg, Map.get(args, String.to_atom(arg)))
      String.replace(acc, colon_arg, value)
    end)
  end

  defp do_call_command(command, args) do
    {:ok, %Rambo{err: err, out: out, status: status}} = Rambo.run(command, args)

    case status do
      0 ->
        {:ok, out}

      _not_zero ->
        {:error, err}
    end
  end

  defp prepare_output(output), do: output
end
