defmodule Octopus.Interface.JsonApi.Output do
  def call(output, "map") do
    {:ok, Jason.decode!(output)}
  end
end
