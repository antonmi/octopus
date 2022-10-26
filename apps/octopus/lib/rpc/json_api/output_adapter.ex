defmodule Octopus.Rpc.JsonApi.OutputAdapter do
  def call(output, "map") do
    {:ok, Jason.decode!(output)}
  end
end
