defmodule Octopus.Interface.XmlApi.Output do
  alias Octopus.Utils

  def call(output, %{"transform" => %{"template" => template, "eval" => eval}}) do
    result = Utils.eval_template(template, output, eval)
    {:ok, result}
  end
end
