defmodule Octopus.Interface do
  defmacro __using__(opts) do
    quote do
      @input Keyword.get(unquote(opts), :input)
      @call Keyword.get(unquote(opts), :call)
      @output Keyword.get(unquote(opts), :output)

      def define(definition) do
        service_name = Macro.camelize(definition["name"])
        interface_module_name = Macro.camelize(definition["type"])

        template()
        |> EEx.eval_file(
          service_name: service_name,
          interface_module_name: interface_module_name,
          interface: definition["interface"]
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
        "../.."
        |> Path.expand(__ENV__.file)
        |> Path.join("service")
        |> Path.join("template.eex")
      end

      defp eval_code(code) do
        quoted = Code.string_to_quoted!(code)
        {value, _binding} = Code.eval_quoted(quoted)
        {:ok, code}
      end
    end
  end
end
