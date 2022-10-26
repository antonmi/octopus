defmodule Octopus.Rpc.UnixCommand.OutputAdapter do
  def call(output, "binary") do
    {:ok, output}
  end
end
