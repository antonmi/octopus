defmodule Octopus do
  @spec define(map()) :: {:ok, String.t()}
  def define(definition) do
    definition
    |> Octopus.Definition.new()
    |> Octopus.Definition.define()
  end
end
