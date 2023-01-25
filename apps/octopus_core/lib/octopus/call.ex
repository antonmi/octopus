defmodule Octopus.Call do
  alias Octopus.{Transform, Validate}

  @spec call(atom(), map(), map(), any()) :: {:ok, map()} | {:error, any()}
  def call(client_module, args, interface_configs, state)
      when is_atom(client_module) and is_map(args) and is_map(interface_configs) do
    with {:ok, args} <- Validate.validate(args, Map.get(interface_configs, "input", %{})),
         {:ok, args} <-
           Transform.transform(args, Map.get(interface_configs, "prepare", false)),
         {:ok, args} <-
           apply(client_module, :call, [args, Map.get(interface_configs, "call", %{}), state]),
         {:ok, args} <-
           Transform.transform(args, Map.get(interface_configs, "transform", false)),
         {:ok, args} <- Validate.validate(args, Map.get(interface_configs, "output", %{})) do
      {:ok, args}
    else
      {:error, error} -> {:error, error}
    end
  end
end
