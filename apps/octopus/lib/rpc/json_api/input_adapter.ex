defmodule Octopus.Rpc.JsonApi.InputAdapter do
  def call(args, %{"args" => args_config}) do
    case validate_args(args, args_config) do
      {:ok, args} ->
        {:ok, args}
    end
  end

  def validate_args(args, args_config) do
    # TODO
    {:ok, args}
  end
end
