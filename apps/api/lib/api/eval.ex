defmodule Api.Eval do
  alias Octopus.ApiEval

  def eval(name, function, payload) do
    ApiEval.eval(name, function, payload)
  end
end
