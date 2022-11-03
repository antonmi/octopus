defmodule Octopus.Interface.XmlApi.Input do
  alias Octopus.Utils

  def call(args, %{
        "args" => _args_config,
        "transform" => %{"template" => template, "eval" => eval}
      }) do
    args = Utils.eval_template(template, args, eval)
    {:ok, args}
  end

  def call(args, %{"args" => _args_config}) do
    {:ok, args}
  end

  def validate_args(args, args_config) do
    # TODO
    {:ok, args}
  end
end
