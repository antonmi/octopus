defmodule Octopus.Interface.UnixCommand.Output do
  def call(output, "binary") do
    {:ok, output}
  end
end
