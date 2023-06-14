defmodule Octopus.Call do
  @moduledoc """
  Implements the call/1 function for the generated modules.
  See Octopus.Definition.
  """
  defstruct client_module: nil,
            args: %{},
            interface_configs: %{},
            helpers: [],
            state: nil

  alias Octopus.{CallError, Transform, Validate}

  @spec call(%__MODULE__{}) :: {:ok, map()} | {:error, any()}
  def call(%__MODULE__{
        client_module: client_module,
        args: args,
        interface_configs: interface_configs,
        helpers: helpers,
        state: state
      })
      when is_atom(client_module) and is_map(args) and is_map(interface_configs) do
    with {:ok, args} <- Validate.validate(args, Map.get(interface_configs, "input", %{}), :input),
         {:ok, args} <-
           Transform.transform(
             args,
             Map.get(interface_configs, "prepare", false),
             helpers,
             :prepare
           ),
         {:ok, args} <- do_apply(client_module, interface_configs, args, state),
         {:ok, args} <-
           Transform.transform(
             args,
             Map.get(interface_configs, "transform", false),
             helpers,
             :transform
           ),
         {:ok, args} <-
           Validate.validate(args, Map.get(interface_configs, "output", %{}), :output) do
      {:ok, args}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp do_apply(client_module, interface_configs, args, state) do
    apply(client_module, :call, [args, Map.get(interface_configs, "call", %{}), state])
  rescue
    error ->
      {:error,
       %CallError{type: :call, message: Exception.message(error), stacktrace: __STACKTRACE__}}
  end
end
