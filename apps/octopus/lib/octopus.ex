defmodule Octopus do
  @moduledoc """
  Top-level module Octopus interface.
  """
  alias Octopus.{Configs, Definition, Utils}

  @spec define(String.t()) :: {:ok, String.t()} | {:error, any()}
  def define(definition) when is_binary(definition) do
    definition
    |> Jason.decode!()
    |> define()
  end

  @spec define(map()) :: {:ok, String.t()} | {:error, any()}
  def define(definition) when is_map(definition) do
    definition = Definition.new(definition)

    case status(definition.name) do
      :undefined ->
        Definition.define(definition)

      :not_ready ->
        Definition.define(definition)

      :ready ->
        {:error, :already_started}
    end
  rescue
    error ->
      {:error, error}
  end

  @spec services :: list(String.t())
  def services do
    :code.all_loaded()
    |> Enum.map(&Atom.to_string(elem(&1, 0)))
    |> Enum.filter(&String.starts_with?(&1, "Elixir.#{Configs.services_namespace()}."))
    |> Enum.map(&String.to_existing_atom/1)
    |> Enum.filter(&Keyword.has_key?(&1.__info__(:functions), :octopus_service_module?))
    |> Enum.map(&apply(&1, :name, []))
  end

  @spec definition(String.t()) :: {:ok, map()} | {:error, any}
  def definition(service_name) do
    case status(service_name) do
      :undefined ->
        {:error, :undefined}

      :not_ready ->
        {:ok, module} = build_module(service_name)
        {:ok, apply(module, :definition, [])}

      :ready ->
        {:ok, module} = build_module(service_name)
        {:ok, apply(module, :definition, [])}
    end
  end

  @spec start(String.t(), map()) :: {:ok, map()} | {:error, any}
  def start(service_name, args \\ %{}) when is_binary(service_name) and is_map(args) do
    case status(service_name) do
      :undefined ->
        {:error, :undefined}

      :not_ready ->
        {:ok, module} = build_module(service_name)
        apply(module, :start, [args])

      :ready ->
        {:error, :already_started}
    end
  rescue
    error ->
      {:error, inspect(error)}
  end

  @spec state(String.t()) :: {:ok, map()} | {:error, any}
  def state(service_name) do
    case status(service_name) do
      :undefined ->
        {:error, :undefined}

      :not_ready ->
        {:error, :not_ready}

      :ready ->
        {:ok, module} = build_module(service_name)
        {:ok, apply(module, :state, [])}
    end
  end

  @spec call(String.t(), String.t(), map()) :: {:ok, map()} | {:error, any()}
  def call(service_name, function_name, args)
      when is_binary(service_name) and is_binary(function_name) and is_map(args) do
    case status(service_name) do
      :undefined ->
        {:error, :undefined}

      :not_ready ->
        {:error, :not_ready}

      :ready ->
        {:ok, module} = build_module(service_name)
        apply(module, String.to_atom(function_name), [args])
    end
  rescue
    error ->
      {:error, error}
  end

  @spec stop(String.t(), map()) :: :ok | {:error, any()}
  def stop(service_name, args \\ %{}) when is_binary(service_name) and is_map(args) do
    case status(service_name) do
      :undefined ->
        {:error, :undefined}

      :not_ready ->
        {:error, :not_ready}

      :ready ->
        {:ok, module} = build_module(service_name)
        apply(module, :stop, [args])
    end
  rescue
    error ->
      {:error, error}
  end

  @spec restart(String.t(), map()) :: {:ok, map()} | {:error, any()}
  def restart(service_name, args \\ %{}) do
    case status(service_name) do
      :undefined ->
        {:error, :undefined}

      :not_ready ->
        {:error, :not_ready}

      :ready ->
        {:ok, module} = build_module(service_name)
        :ok = apply(module, :stop, [args])
        apply(module, :start, [args])
    end
  rescue
    error ->
      {:error, error}
  end

  @spec delete(String.t(), map()) :: :ok | {:error, any()}
  def delete(service_name, args \\ %{}) do
    case status(service_name) do
      :undefined ->
        {:error, :undefined}

      :not_ready ->
        {:ok, module} = build_module(service_name)
        do_delete(module)

      :ready ->
        {:ok, module} = build_module(service_name)
        :ok = apply(module, :stop, [args])
        do_delete(module)
    end
  rescue
    error ->
      {:error, error}
  end

  defp do_delete(module) do
    :code.soft_purge(:"#{module}.State")
    :code.soft_purge(module)
    :code.delete(:"#{module}.State")
    :code.delete(module)
    :ok
  end

  @spec status(String.t()) :: :undefined | :not_ready | :ready
  def status(service_name) when is_binary(service_name) do
    case build_module(service_name) do
      {:ok, module} ->
        case module.ready?() do
          true -> :ready
          false -> :not_ready
        end

      {:error, :not_found} ->
        :undefined
    end
  end

  defp build_module(service_name) do
    module_name = Utils.modulize(service_name)
    namespace = Configs.services_namespace()
    module = String.to_atom("Elixir.#{namespace}.#{module_name}")

    if Utils.module_exist?(module) do
      {:ok, module}
    else
      {:error, :not_found}
    end
  end
end
