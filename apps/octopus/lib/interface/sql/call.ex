defmodule Octopus.Interface.Sql.Call do
  alias Octopus.Utils

  def call(input, config) do
    Postgrex.query(process_name(config["process_name"]), config["query"], input)
  end

  defp process_name(name) do
    String.to_atom("Elixir.#{Utils.modulize(name)}")
  end
end
