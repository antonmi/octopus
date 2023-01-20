defmodule Octopus.Definition do
  alias Octopus.{Configs, Utils}
  defstruct [:name, :client, :interface]

  def new(definition) do
    %__MODULE__{
      name: definition["name"],
      client: definition["client"],
      interface: definition["interface"]
    }
  end

  def define(definition) do
    service_module = Utils.modulize(definition.name)
    client_module = Utils.modulize(definition.client["module"])
    adapter_name = definition.client["adapter"] || definition.client["module"] <> ".Adapter"
    adapter_module = Utils.modulize(adapter_name)

    template()
    |> EEx.eval_string(
      namespace: namespace(),
      service_module: service_module,
      client_module: client_module,
      client_module_start_config: definition.client["start"],
      adapter_module: adapter_module,
      interface: definition.interface
    )
    |> eval_code()
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
          Octopus.Call.call(<%= adapter_module %>, args, @interface_configs_<%= name %>, state())
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
end
