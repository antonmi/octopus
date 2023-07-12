defmodule Octopus.Configs do
  def services_namespace do
    case Application.get_env(:octopus, :services_namespace) do
      nil ->
        "Octopus.Services"
      namespace when is_atom(namespace) ->
        String.replace("#{namespace}", "Elixir.", "")
      namespace when is_binary(namespace) ->
        namespace
    end
  end
end
