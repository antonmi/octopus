defmodule Api.Eval do
  alias Octopus.ApiEval

  def eval(path, payload) do
    ApiEval.eval(path, payload)
  end
end
