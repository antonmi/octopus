defmodule Octopus.EvalTest do
  use ExUnit.Case, async: true

  test "eval_string" do
    assert Octopus.Eval.eval_string("1 + 1", []) == {:ok, 2}
  end

  test "it does not allow calling external functions" do
    string = "File.read(\"/etc/passwd\")"

    {:error, error} = Octopus.Eval.eval_string(string, [])
    assert error =~ "%RuntimeError{message: \"Non local call"
  end

  test "it does not :os.cmd/1 calling external functions" do
    string = ":os.cmd(\"ls\")"

    {:error, error} = Octopus.Eval.eval_string(string, [])
    assert error =~ "%RuntimeError{message: \"Non local call"
  end

  test "it allows Access module" do
    args = %{"list" => [1, 2, 3]}
    {:ok, result} = Octopus.Eval.eval_string("get_in(args['list'], [Access.at(1)])", args: args)
    assert result == 2

    args = %{"user" => %{"name" => "Anton"}}

    {:ok, result} =
      Octopus.Eval.eval_string("get_in(args, [Access.key('user'), Access.key('name')])",
        args: args
      )

    assert result == "Anton"
  end

  test "to_string" do
    args = %{"x" => 1}
    {:ok, result} = Octopus.Eval.eval_string("to_string(args['x'])", args: args)
    assert result == "1"
  end

  test "with variables" do
    args = %{"x" => 1, "y" => 2}
    template = "{args[\"x\"], args[\"y\"], \"path/#{args["x"]}\"}"
    assert Octopus.Eval.eval_string(template, args: args) == {:ok, {1, 2, "path/1"}}
  end

  test "with single quotes" do
    args = %{"foo" => "the_foo"}
    {:ok, result} = Octopus.Eval.eval_string("args['foo'] <> 'baz'", args: args)
    assert result == "the_foobaz"
  end

  test "eval string without code" do
    {:error, error} = Octopus.Eval.eval_string("my_string", [])
    assert error =~ "%SyntaxError{file:"
  end

  test "for non string" do
    assert {:error, "1 is not a string"} = Octopus.Eval.eval_string(1, [])
    assert {:error, _} = Octopus.Eval.eval_string([2, 3], [])
    assert {:error, "aaa is not a string"} = Octopus.Eval.eval_string(:aaa, [])
  end

  test "case condition" do
    code = "case args[\"x\"] do
      1 -> true
      2 -> false
    end
    "
    assert Octopus.Eval.eval_string(code, args: %{"x" => 1}) == {:ok, true}
    assert Octopus.Eval.eval_string(code, args: %{"x" => 2}) == {:ok, false}
  end

  test "cond condition" do
    code = "cond do
      args[\"x\"] == 1 -> true
      args[\"x\"] == 2 -> false
      true -> nil
    end
    "
    assert Octopus.Eval.eval_string(code, args: %{"x" => 1}) == {:ok, true}
    assert Octopus.Eval.eval_string(code, args: %{"x" => 2}) == {:ok, false}
    assert Octopus.Eval.eval_string(code, args: %{"x" => 3}) == {:ok, nil}
  end

  test "if and unless conditions" do
    code = "if args[\"x\"] > 0, do: true, else: false"
    assert Octopus.Eval.eval_string(code, args: %{"x" => 1}) == {:ok, true}
    assert Octopus.Eval.eval_string(code, args: %{"x" => -1}) == {:ok, false}
  end

  describe "with helper module" do
    defmodule Helpers do
      def add(args), do: args["x"] + args["y"]
    end

    defmodule OtherHelpers do
      def mult(args), do: args["x"] * args["y"]
    end

    test "it allows calling functions from the helper module" do
      args = %{"x" => 1, "y" => 2}
      template = "add(args)"

      assert Octopus.Eval.eval_string(
               template,
               args: args,
               helpers: [Helpers, OtherHelpers]
             ) == {:ok, 3}

      assert Octopus.Eval.eval_string(
               "mult(args)",
               args: args,
               helpers: [Helpers, OtherHelpers]
             ) == {:ok, 2}
    end
  end
end
