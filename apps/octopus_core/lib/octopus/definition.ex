defmodule Octopus.DefinitionError do
  defexception [:message]
end

defmodule Octopus.Definition do
  alias Octopus.{Configs, DefinitionError, Utils}
  defstruct [:name, :client, :interface]

  def new(definition) do
    name = definition["name"] || raise DefinitionError, "Missing service name!"
    client = definition["client"] || raise DefinitionError, "Missing client definition!"
    interface = definition["interface"] || raise DefinitionError, "Missing interface definition!"

    %__MODULE__{
      name: name,
      client: client,
      interface: interface
    }
  end

  def define(definition) do
    service_module = Utils.modulize(definition.name)

    client_module =
      definition.client["module"]
      |> Utils.modulize()
      |> validate_module_or_raise()

    template()
    |> EEx.eval_string(
      namespace: namespace(),
      service_module: service_module,
      client_module: client_module,
      client_module_start_config: definition.client["start"],
      interface: definition.interface
    )
    |> eval_code()
    |> case do
      {:ok, _code} ->
        {:ok, definition.name}
    end
  end

  def define_state(module, state) do
    template_for_state()
    |> EEx.eval_string(module: module, state: state)
    |> eval_code()
  end

  defp template() do
    """
    defmodule <%= namespace %>.<%= service_module %> do
      def ok?, do: true

      @start_configs "<%= Base.encode64(:erlang.term_to_binary(client_module_start_config)) %>"
                     |> Base.decode64!()
                     |> :erlang.binary_to_term()

      def start(args \\\\ %{}) do
        case <%= client_module %>.start(args, @start_configs) do
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
          :not_started
      end

      <%= for {name, configs} <- interface do %>
        @interface_configs_<%= name %> "<%= Base.encode64(:erlang.term_to_binary(configs)) %>"
                                       |> Base.decode64!()
                                       |> :erlang.binary_to_term()

        def <%= name %>(args) do
          Octopus.Call.call(<%= client_module %>, args, @interface_configs_<%= name %>, state())
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

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {_value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end

  defp validate_module_or_raise(module) do
    unless Utils.module_exist?(String.to_atom("Elixir.#{module}")) do
      raise DefinitionError, "Module '#{module}' doesn't exist!"
    end

    module
  end
end
