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
    error_configs = Map.get(interface_configs, "error", false)

    case apply(client_module, :call, [args, Map.get(interface_configs, "call", %{}), state]) do
      {:ok, result} ->
        {:ok, result}

      {:error, error} ->
        handle_error(error_configs, error, helpers)
    end
  rescue
    error ->
      {:error,
       %CallError{
         step: :call,
         error: error,
         message: Exception.message(error),
         stacktrace: Exception.format_stacktrace(__STACKTRACE__)
       }}
  end

  defp handle_error(error_configs, error, helpers) do
    {error, message} =
      case error do
        string when is_binary(string) ->
          {string, string}

        exception when is_exception(exception) ->
          {exception, Exception.message(exception)}

        args when is_map(args) ->
          {args, inspect(args)}

        other ->
          {other, inspect(other)}
      end

    if error_configs do
      {:skip,
       transform_error(
         %{
           "step" => "call",
           "error" => allow_only_binary_and_map(error),
           "message" => message,
           "stacktrace" => Exception.format_stacktrace()
         },
         error_configs,
         helpers
       )}
    else
      {:error,
       %CallError{
         step: :call,
         error: error,
         message: message,
         stacktrace: Exception.format_stacktrace()
       }}
    end
  end

  defp allow_only_binary_and_map(error) do
    if is_binary(error) or (is_map(error) and not is_exception(error)) do
      error
    else
      inspect(error)
    end
  end

  defp transform_error(args, error_configs, helpers) do
    Transform.transform(args, error_configs, helpers, :error)
  end
end
