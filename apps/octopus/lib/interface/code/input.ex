defmodule Octopus.Interface.Code.Input do
  alias Octopus.Utils

  def call(args, %{
        "transform" => %{"template" => template, "eval" => eval},
        "args" => args_config
      }) do
    {:ok, Utils.eval_template(template, args, eval)}
  end
end
