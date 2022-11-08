defmodule Octopus.Definition do
  alias Octopus.{Configs, Utils}

  def define(service_name, interface_definition) do
    service_name = Utils.modulize(service_name)
    interface_module_name = Utils.modulize(interface_definition["type"])

    template()
    |> EEx.eval_string(
      namespace: namespace(),
      service_name: service_name,
      interface_module_name: interface_module_name,
      interface: interface_definition
    )
    |> eval_code()
    |> case do
      {:ok, code} ->
        {:ok, code}
    end
  end

  defp template() do
    """
    defmodule <%= namespace %>.<%= service_name %> do
      <%= for {name, attrs} <- interface do %>
        def <%= name %>(args) do
          Octopus.Interface.<%= interface_module_name %>.call(args, "<%= Base.encode64(:erlang.term_to_binary(attrs)) %>")
        end
      <% end %>
    end
    """
  end

  defp namespace do
    Configs.services_namespace()
  end

  defp eval_code(code) do
    quoted = Code.string_to_quoted!(code)
    {value, _binding} = Code.eval_quoted(quoted)
    {:ok, code}
  end
end
