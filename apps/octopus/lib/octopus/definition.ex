defmodule Octopus.Definition do
  @moduledoc """
  Compiles the interface definition into a module.
  """
  alias Octopus.{Configs, Error, Utils}
  defstruct [:name, :client, :interface, :helpers, :json_definition]

  @spec new(map()) :: %Octopus.Definition{} | no_return()
  def new(definition) do
    name = definition["name"] || raise Error, "Missing service name!"
    client = definition["client"] || raise Error, "Missing client definition!"
    interface = definition["interface"] || raise Error, "Missing interface definition!"
    helpers = definition["helpers"] || []

    %__MODULE__{
      name: name,
      client: client,
      interface: interface,
      helpers: helpers,
      json_definition: definition
    }
  end

  @spec define(map()) :: {:ok, String.t()} | no_return()
  def define(definition) do
    service_module = Utils.modulize(definition.name)

    client_module =
      definition.client["module"]
      |> Utils.modulize()
      |> validate_module_or_raise()

    template()
    |> EEx.eval_string(
      definition: definition.json_definition,
      namespace: namespace(),
      service_module: service_module,
      client_module: client_module,
      client_module_start_config: definition.client["start"] || %{},
      client_module_stop_config: definition.client["stop"] || %{},
      interface: definition.interface,
      helpers: helper_modules(definition.helpers)
    )
    |> eval_code()
    |> case do
      {:ok, _code} ->
        {:ok, definition.name}
    end
  end

  @spec define_state(atom(), any()) :: {:ok, String.t()} | no_return()
  def define_state(module, state) do
    template_for_state()
    |> EEx.eval_string(module: module, state: state)
    |> eval_code()
  end

  defp template() do
    """
    defmodule <%= namespace %>.<%= service_module %> do
      @definition "<%= Base.encode64(:erlang.term_to_binary(definition)) %>"
                     |> Base.decode64!()
                     |> :erlang.binary_to_term()

      def definition, do: @definition

      @start_configs "<%= Base.encode64(:erlang.term_to_binary(client_module_start_config)) %>"
                     |> Base.decode64!()
                     |> :erlang.binary_to_term()

      def start(args \\\\ %{}) do
        case <%= client_module %>.start(args, @start_configs, <%= namespace %>.<%= service_module %>) do
          {:ok, state} ->
            Octopus.Definition.define_state(__MODULE__, state)
            {:ok, state}

          {:error, reason} ->
            {:error, reason}
        end
      end

      def state do
        apply(__MODULE__.State, :state, [])
      rescue
        UndefinedFunctionError ->
          raise Octopus.Error, "Service not initiated!"
      end

      def ready? do
        Octopus.Utils.module_exist?(__MODULE__.State)
      end

      @stop_configs "<%= Base.encode64(:erlang.term_to_binary(client_module_stop_config)) %>"
                     |> Base.decode64!()
                     |> :erlang.binary_to_term()

      def stop(args \\\\ %{}) do
        <%= client_module %>.stop(args, @stop_configs, state())
        :code.soft_purge(__MODULE__.State)
        :code.delete(__MODULE__.State)
        :ok
      end

      @helpers "<%= Base.encode64(:erlang.term_to_binary(helpers)) %>"
               |> Base.decode64!()
               |> :erlang.binary_to_term()
      
      <%= for {name, configs} <- interface do %>
        @interface_configs_<%= name %> "<%= Base.encode64(:erlang.term_to_binary(configs)) %>"
                                       |> Base.decode64!()
                                       |> :erlang.binary_to_term()

        def <%= name %>(args) do
          %Octopus.Call{
            client_module: <%= client_module %>,
            args: args,
            interface_configs: @interface_configs_<%= name %>,
            helpers: @helpers,
            state: state()
          }
          |> Octopus.Call.call()
        end
      <% end %>
    end
    """
  end

  defp template_for_state() do
    """
    defmodule <%= module %>.State do
      @state "<%= Base.encode64(:erlang.term_to_binary(state)) %>"
                             |> Base.decode64!()
                             |> :erlang.binary_to_term()
      def state do
        @state
      end
    end
    """
  end

  defp namespace do
    Configs.services_namespace()
  end

  defp helper_modules(helpers) do
    helpers
    |> Enum.map(&Utils.modulize/1)
    |> Enum.map(&validate_module_or_raise/1)
    |> Enum.map(&String.to_atom("Elixir.#{&1}"))
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {_value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end

  defp validate_module_or_raise(module) do
    unless Utils.module_exist?(String.to_atom("Elixir.#{module}")) do
      raise Error, "Module '#{module}' doesn't exist!"
    end

    module
  end
end
