defmodule Octopus.Interface.Sql.Output do
  def call(output, "map") do
    {:ok, Map.from_struct(output)}
  end
end
