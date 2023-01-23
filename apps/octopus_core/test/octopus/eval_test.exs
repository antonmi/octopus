defmodule Octopus.EvalTest do
  use ExUnit.Case, async: true

  test "eval_string" do
    assert Octopus.Eval.eval_string("1 + 1", []) == 2
  end

  test "it does not allow calling external functions" do
    string = "File.read(\"/etc/passwd\")"
    result = Octopus.Eval.eval_string(string, [])
    assert result == string
  end

  test "with variables" do
    args = %{"x" => 1, "y" => 2}
    template = "{args[\"x\"], args[\"y\"], \"path/#{args["x"]}\"}"
    assert Octopus.Eval.eval_string(template, args: args) == {1, 2, "path/1"}
  end

  test "with single quotes" do
    args = %{"foo" => "the_foo"}
    result = Octopus.Eval.eval_string("args['foo'] <> 'baz'", args: args)
    assert result == "the_foobaz"
  end

  test "eval string without code" do
    assert Octopus.Eval.eval_string("my_string", []) == "my_string"
  end

  test "for non string" do
    assert Octopus.Eval.eval_string(1, []) == 1
    assert Octopus.Eval.eval_string([2, 3], []) == [2, 3]
    assert Octopus.Eval.eval_string(:aaa, []) == :aaa
  end

  describe "with helper module" do
    defmodule Helpers do
      def add(args), do: args["x"] + args["y"]
    end

    defmodule OtherHelpers do
      def mult(args), do: args["x"] * args["y"]
    end

    test "it allows calling functions from the module" do
      args = %{"x" => 1, "y" => 2}
      template = "add(args)"

      assert Octopus.Eval.eval_string(
               template,
               args: args,
               helpers: [Helpers, OtherHelpers]
             ) == 3

      assert Octopus.Eval.eval_string(
               "mult(args)",
               args: args,
               helpers: [Helpers, OtherHelpers]
             ) == 2
    end
  end
end
