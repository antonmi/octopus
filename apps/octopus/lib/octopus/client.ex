defmodule Octopus.Client do
  @callback start(map(), map(), atom()) :: {:ok, map()} | {:error, any()} | no_return()
  @callback call(map(), map(), any()) :: {:ok, map()} | {:error, any()} | no_return()
  @callback stop(map(), map(), any()) :: :ok | {:error, any()} | no_return()
end
