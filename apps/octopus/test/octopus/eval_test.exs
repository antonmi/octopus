defmodule Octopus.EvalTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  test "eval_string" do
    assert Octopus.Eval.eval_string("1 + 1", []) == 2
  end

  test "it does not allow calling external functions" do
    string = "File.read(\"/etc/passwd\")"

    capture_log(fn ->
      result = Octopus.Eval.eval_string(string, [])
      assert result == string
    end) =~ "[error]"
  end

  test "it does not :os.cmd/1 calling external functions" do
    string = ":os.cmd(\"ls\")"

    capture_log(fn ->
      result = Octopus.Eval.eval_string(string, [])
      assert result == string
    end) =~ "[error]"
  end

  test "it allows Access module" do
    args = %{"list" => [1, 2, 3]}
    result = Octopus.Eval.eval_string("get_in(args['list'], [Access.at(1)])", args: args)
    assert result == 2

    args = %{"user" => %{"name" => "Anton"}}

    result =
      Octopus.Eval.eval_string("get_in(args, [Access.key('user'), Access.key('name')])",
        args: args
      )

    assert result == "Anton"
  end

  test "to_string" do
    args = %{"x" => 1}
    result = Octopus.Eval.eval_string("to_string(args['x'])", args: args)
    assert result == "1"
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
    capture_log(fn ->
      assert Octopus.Eval.eval_string("my_string", []) == "my_string"
    end) =~ "[error]"
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
