defmodule Octopus.Rpc.UnixCommand.Input do
  def call(args, %{"transform" => transform, "args" => args_config}) when is_binary(transform) do
    case validate_args(args, args_config) do
      {:ok, args} ->
        input =
          ~r{:(\w+\b)}
          |> Regex.scan(transform)
          |> Enum.reduce(transform, fn [colon_arg, arg], acc ->
            value = Map.fetch!(args, arg)
            String.replace(acc, colon_arg, value)
          end)

        {:ok, input}

      {:error, :invalid_arguments} ->
        {:error, :invalid_arguments}
    end
  end

  def validate_args(args, args_config) do
    # TODO
    {:ok, args}
  end
end
