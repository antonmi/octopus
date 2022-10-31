defmodule Octopus.Interface.Cli.Input do
  alias Octopus.Utils

  def call(args, %{
        "transform" => %{"template" => template, "eval" => eval},
        "args" => args_config
      }) do
    case validate_args(args, args_config) do
      {:ok, args} ->
        Utils.eval_template(template, args, eval)

      {:error, :invalid_arguments} ->
        {:error, :invalid_arguments}
    end
  end

  def validate_args(args, args_config) do
    # TODO
    {:ok, args}
  end
end
