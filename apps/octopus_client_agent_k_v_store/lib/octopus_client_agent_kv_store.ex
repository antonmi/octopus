defmodule OctopusClientAgentKVStore do
  @moduledoc """
  Simple key-value storage based on Agent.
  """

  @spec start(map(), map(), atom()) :: {:ok, map()} | {:error, :already_started}
  def start(%{}, %{}, service_module) do
    spec = %{
      id: service_module,
      start: {Agent, :start_link, [fn -> %{} end, [name: service_module]]}
    }

    case DynamicSupervisor.start_child(__MODULE__.DynamicSupervisor, spec) do
      {:ok, pid} ->
        state = %{pid: pid, name: service_module}

        {:ok, state}

      {:error, {:already_started, _pid}} ->
        {:error, :already_started}
    end
  end

  @spec call(map(), map(), any()) :: {:ok, map()} | {:error, any()}
  def call(args, %{}, state) do
    operation = args["operation"]

    with :ok <- validate_operation(operation, args),
         {:ok, result} <- call_operation(operation, args, state) do
      {:ok, result}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec stop(map(), map(), any()) :: :ok | {:error, :not_found}
  def stop(%{}, %{}, state) do
    DynamicSupervisor.terminate_child(__MODULE__.DynamicSupervisor, state.pid)
  end

  defp validate_operation("set", %{"key" => _, "value" => _}), do: :ok
  defp validate_operation("get", %{"key" => _}), do: :ok
  defp validate_operation("getset", %{"key" => _, "value" => _}), do: :ok

  defp validate_operation(_unknown_operation, _args) do
    {:error, :invalid_operation_or_missing_arguments}
  end

  defp call_operation("set", %{"key" => key, "value" => value}, %{pid: pid}) do
    :ok = Agent.update(pid, &Map.put(&1, key, value))
    {:ok, "ok"}
  end

  defp call_operation("get", %{"key" => key}, %{pid: pid}) do
    value = Agent.get(pid, &Map.get(&1, key))
    {:ok, value}
  end

  defp call_operation("getset", %{"key" => key, "value" => value}, %{pid: pid}) do
    value =
      Agent.get_and_update(pid, fn data -> {Map.get(data, key), Map.put(data, key, value)} end)

    {:ok, value}
  end
end
