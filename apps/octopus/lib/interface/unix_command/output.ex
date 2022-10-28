defmodule Octopus.Interface.Cli.Output do
  def call(output, "binary") do
    {:ok, output}
  end
end
