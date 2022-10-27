defmodule Octopus.Execution.Process do
  #  use Octopus.Run, start: __MODULE__.Start

  def run(args) do
    __MODULE__.Start.call(args["start"])
  end
end
