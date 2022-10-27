defmodule Octopus.Interface do
  defmacro __using__(opts) do
    quote do
      @input Keyword.get(unquote(opts), :input)
      @call Keyword.get(unquote(opts), :call)
      @output Keyword.get(unquote(opts), :output)

      def define(service_name, interface_definition) do
        service_name = Macro.camelize(service_name)
        interface_module_name = Macro.camelize(interface_definition["type"])

        template()
        |> EEx.eval_string(
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

      def call(args, config) do
        config = :erlang.binary_to_term(Base.decode64!(config))

        with {:ok, input} <- @input.call(args, config["input"]),
             {:ok, body} <- @call.call(input, config["call"]),
             {:ok, formatted_output} <- @output.call(body, config["output"]) do
          {:ok, formatted_output}
        end
      end

      defp template() do
        """
        defmodule Octopus.Service.<%= service_name %> do
          <%= for {name, attrs} <- interface do %>
            def <%= name %>(args) do
              Octopus.Interface.<%= interface_module_name %>.call(args, "<%= Base.encode64(:erlang.term_to_binary(attrs)) %>")
            end
          <% end %>
        end
        """
      end

      defp eval_code(code) do
        quoted = Code.string_to_quoted!(code)
        {value, _binding} = Code.eval_quoted(quoted)
        {:ok, code}
      end
    end
  end
end
