defmodule Octopus.Interface do
  defmacro __using__(opts) do
    quote do
      @input Keyword.get(unquote(opts), :input)
      @call Keyword.get(unquote(opts), :call)
      @output Keyword.get(unquote(opts), :output)

      def call(args, config) do
        config = :erlang.binary_to_term(Base.decode64!(config))

        with {:ok, input} <- @input.call(args, config["input"]),
             {:ok, body} <- @call.call(input, config["call"]),
             {:ok, formatted_output} <- @output.call(body, config["output"]) do
          {:ok, formatted_output}
        end
      end
    end
  end
end
