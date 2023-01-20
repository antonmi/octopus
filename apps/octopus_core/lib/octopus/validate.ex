defmodule Octopus.Validate do
  alias ExJsonSchema.Validator

  @spec validate(map(), map()) :: {:ok, map()} | {:error, any()}
  def validate(args, schema) do
    schema
    |> wrap_properties()
    |> Validator.validate(args)
    |> case do
      :ok ->
        {:ok, args}

      {:error, errors} ->
        {:error, errors}
    end
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
end
