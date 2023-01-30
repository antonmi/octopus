defmodule OctopusClientCliRambo do
  @moduledoc false
  @behaviour Octopus.Client

  @spec start(map(), map(), atom()) :: {:ok, map()}
  def start(_args, _configs \\ %{}, _service_name) do
    {:ok, %{}}
  end

  @spec call(map(), map(), map()) :: {:ok, map()} | {:error, String.t()}
  def call(args, configs, state) do
    case do_call_rambo(args["command"], args["input"], state) do
      {:ok, %{status: status, out: out}} ->
        out =
          if configs["split_by_newline"] do
            out |> String.split("\n") |> Enum.map(&String.trim/1)
          else
            out
          end

        {:ok, %{"status" => status, "out" => out}}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec stop(map(), map(), map()) :: :ok
  def stop(_args, _configs, _state) do
    :ok
  end

  defp do_call_rambo(command, input, %{}) do
    case Rambo.run(command, input) do
      {:ok, %Rambo{err: err, out: out, status: status}} ->
        case status do
          0 ->
            {:ok, %{status: status, out: out}}

          _not_zero ->
            {:error, err}
        end

      {:error, error} ->
        {:error, inspect(error)}
    end
  end
end
