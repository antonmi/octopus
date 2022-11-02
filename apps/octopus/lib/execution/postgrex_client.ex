defmodule Octopus.Execution.PostgrexClient do
  #  use Octopus.Execution, start: __MODULE__.Start

  def run(args) do
    __MODULE__.Start.call(args["start"])
  end
end
