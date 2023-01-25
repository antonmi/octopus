defmodule Octopus.Eval do
  require Logger

  def eval_string(string, args) when is_binary(string) do
    do_eval_string(string, args)
  rescue
    error ->
      Logger.error(inspect(error))
      string
  end

  def eval_string(arg, _args), do: arg

  defp do_eval_string(string, args) do
    {value, _} =
      string
      |> String.replace("'", "\"")
      |> Code.string_to_quoted!(existing_atoms_only: true)
      |> locals_calls_only()
      |> limit_kernel_calls()
      |> import_helpers(Keyword.get(args, :helpers, []))
      |> Code.eval_quoted(args)

    value
  end

  defp locals_calls_only(ast) do
    ast
    |> Macro.prewalk(fn
      {{:., _, [Access, _]}, _, _} = code ->
        code

      {{:., _, [{:__aliases__, [line: 1], [:Access]}, _]}, _, _} = code ->
        code

      {{:., _, _}, _, _} = bad ->
        raise("Non local call #{inspect(bad)}")

      {:eval, _, args} when is_list(args) ->
        raise("No eval")

      code ->
        code
    end)
  end

  def limit_kernel_calls(ast) do
    quote do
      import Kernel,
        only: [
          !=: 2,
          !==: 2,
          *: 2,
          **: 2,
          +: 1,
          +: 2,
          ++: 2,
          -: 1,
          -: 2,
          --: 2,
          /: 2,
          <: 2,
          <=: 2,
          <>: 2,
          ==: 2,
          ===: 2,
          =~: 2,
          >: 2,
          >=: 2,
          abs: 1,
          byte_size: 1,
          ceil: 1,
          div: 2,
          elem: 2,
          floor: 1,
          get_in: 2,
          hd: 1,
          inspect: 1,
          inspect: 2,
          is_atom: 1,
          is_binary: 1,
          is_bitstring: 1,
          is_boolean: 1,
          is_float: 1,
          is_function: 1,
          is_function: 2,
          is_integer: 1,
          is_list: 1,
          is_map: 1,
          is_map_key: 2,
          is_number: 1,
          is_pid: 1,
          is_port: 1,
          is_reference: 1,
          is_tuple: 1,
          length: 1,
          map_size: 1,
          max: 2,
          min: 2,
          pop_in: 2,
          put_elem: 3,
          put_in: 3,
          rem: 2,
          round: 1,
          tl: 1,
          to_string: 1,
          trunc: 1,
          tuple_size: 1,
          update_in: 3
        ]

      unquote(ast)
    end
  end

  defp import_helpers(ast, []) do
    quote do
      unquote(ast)
    end
  end

  defp import_helpers(ast, modules) do
    Enum.reduce(modules, ast, fn module, acc ->
      quote do
        import unquote(module)
        unquote(acc)
      end
    end)
  end
end
