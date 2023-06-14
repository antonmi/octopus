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
         {:ok, args} <- do_call(client_module, interface_configs, args, state, helpers),
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
      {:skip, {:ok, args}} ->
        {:ok, args}

      {:error, error} ->
        {:error, error}
    end
  end

  defp do_call(client_module, interface_configs, args, state, helpers) do
    client_error_configs = fetch_client_error_configs(interface_configs)

    case apply(client_module, :call, [args, Map.get(interface_configs, "call", %{}), state]) do
      {:ok, result} ->
        {:ok, result}

      {:error, args} ->
        handle_error(client_error_configs, args, helpers)
    end
  rescue
    error ->
      {:error,
       %CallError{type: :call, message: Exception.message(error), stacktrace: __STACKTRACE__}}
  end

  defp fetch_client_error_configs(interface_configs) do
    Map.get(interface_configs, "client_error") ||
      Map.get(interface_configs, "client-error") ||
      false
  end

  defp handle_error(client_error_configs, args, helpers) do
    case {client_error_configs, args} do
      {false, _args} ->
        {:error, %CallError{type: :call, message: inspect(args)}}

      {_, string} when is_binary(string) ->
        {:skip, transform_error(%{"message" => string}, client_error_configs, helpers)}

      {_, exception} when is_exception(exception) ->
        {:skip,
         transform_error(
           %{"message" => Exception.message(exception)},
           client_error_configs,
           helpers
         )}

      {_, args} when is_map(args) ->
        {:skip, transform_error(args, client_error_configs, helpers)}
    end
  end

  defp transform_error(args, client_error_configs, helpers) do
    Transform.transform(args, client_error_configs, helpers, :client_error)
  end
end
