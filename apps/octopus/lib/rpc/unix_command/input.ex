defmodule Octopus.Rpc.UnixCommand.Input do
  alias Octopus.Utils

  def call(args, %{"transform" => transform, "args" => args_config}) when is_binary(transform) do
    case validate_args(args, args_config) do
      {:ok, args} ->
        {:ok, Utils.eval_pattern(transform, args)}

      {:error, :invalid_arguments} ->
        {:error, :invalid_arguments}
    end
  end

  def validate_args(args, args_config) do
    # TODO
    {:ok, args}
  end
end
