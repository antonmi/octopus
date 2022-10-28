defmodule Octopus.Interface.Code.Output do
  def call(output, "as_is") do
    {:ok, output}
  end
end
