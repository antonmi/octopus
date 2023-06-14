defmodule Octopus.Validate do
  @moduledoc """
  Validates input and output with ExJsonSchema.Validator
  """
  alias ExJsonSchema.Validator
  alias Octopus.CallError

  @spec validate(map(), map(), atom()) :: {:ok, map()} | {:error, any()}
  def validate(args, schema, context \\ :undefined) do
    schema
    |> wrap_properties()
    |> Validator.validate(args)
    |> case do
      :ok ->
        {:ok, args}

      {:error, errors} when is_list(errors) ->
        {:error, %CallError{type: context, message: format_errors(errors)}}
    end
  rescue
    error ->
      {:error,
       %CallError{type: context, message: Exception.message(error), stacktrace: __STACKTRACE__}}
  end

  defp wrap_properties(%{"properties" => properties} = schema) when is_map(properties) do
    Map.merge(schema, %{"type" => "object"})
  end

  defp wrap_properties(schema) when is_map(schema) do
    {required, schema} = Map.pop(schema, "required", [])

    %{
      "type" => "object",
      "properties" => schema,
      "required" => required
    }
  end

  defp format_errors(errors) do
    errors
    |> Enum.map(fn {message, field} -> "#{field}:#{message}" end)
    |> Enum.join("\n")
  end
end
