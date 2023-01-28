defmodule OctopusAgent do
  def define(payload) do
    with {:ok, definition} <- Jason.decode(payload),
         {:ok, service_name} <- Octopus.define(definition) do
      {:ok, Jason.encode!(%{"ok" => service_name})}
    else
      {:error, error} ->
        {:error, Jason.encode!(%{"error" => inspect(error)})}
    end
  end

  def start(service_name), do: start(service_name, "{}")
  def start(service_name, ""), do: start(service_name, "{}")

  def start(service_name, payload) do
    with {:ok, args} <- Jason.decode(payload),
         {:ok, state} <- Octopus.start(service_name, args) do
      {:ok, Jason.encode!(%{"ok" => state})}
    else
      {:error, error} ->
        {:error, Jason.encode!(%{"error" => inspect(error)})}
    end
  end

  def call(service_name, function_name, payload) do
    with {:ok, args} <- Jason.decode(payload),
         {:ok, result} <- Octopus.call(service_name, function_name, args) do
      {:ok, Jason.encode!(%{"ok" => result})}
    else
      {:error, error} ->
        {:error, Jason.encode!(%{"error" => inspect(error)})}
    end
  end

  def stop(service_name), do: stop(service_name, "{}")
  def stop(service_name, ""), do: stop(service_name, "{}")

  def stop(service_name, payload) do
    with {:ok, args} <- Jason.decode(payload),
         :ok <- Octopus.stop(service_name, args) do
      {:ok, Jason.encode!(%{"ok" => "ok"})}
    else
      {:error, error} ->
        {:error, Jason.encode!(%{"error" => inspect(error)})}
    end
  end

  def restart(service_name), do: restart(service_name, "{}")
  def restart(service_name, ""), do: restart(service_name, "{}")

  def restart(service_name, payload) do
    with {:ok, args} <- Jason.decode(payload),
         {:ok, state} <- Octopus.restart(service_name, args) do
      {:ok, Jason.encode!(%{"ok" => state})}
    else
      {:error, error} ->
        {:error, Jason.encode!(%{"error" => inspect(error)})}
    end
  end

  def delete(service_name) do
    case Octopus.delete(service_name) do
      :ok ->
        {:ok, Jason.encode!(%{"ok" => "ok"})}

      {:error, error} ->
        {:error, Jason.encode!(%{"error" => inspect(error)})}
    end
  end

  def status(service_name) do
    status = Octopus.status(service_name)
    {:ok, Jason.encode!(%{"status" => inspect(status)})}
  end
end
