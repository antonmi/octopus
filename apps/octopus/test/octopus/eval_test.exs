defmodule Octopus.EvalTest do
  use ExUnit.Case, async: true

  test "eval_string" do
    assert Octopus.Eval.eval_string("1 + 1", []) == 2
  end

  test "it does not allow calling external functions" do
    string = "File.read(\"/etc/passwd\")"

    assert_raise RuntimeError, fn -> Octopus.Eval.eval_string(string, []) end
  end

  test "it does not :os.cmd/1 calling external functions" do
    string = ":os.cmd(\"ls\")"

    assert_raise RuntimeError, fn -> Octopus.Eval.eval_string(string, []) end
  end

  test "it allows Access module" do
    args = %{"list" => [1, 2, 3]}
    assert Octopus.Eval.eval_string("get_in(args['list'], [Access.at(1)])", args: args) == 2

    args = %{"user" => %{"name" => "Anton"}}

    assert Octopus.Eval.eval_string(
             "get_in(args, [Access.key('user'), Access.key('name')])",
             args: args
           ) == "Anton"
  end

  test "it allows List module" do
    args = %{"list" => [1, 2, 3]}
    assert 1 = Octopus.Eval.eval_string("List.first(args['list'])", args: args)
    args = %{"list" => []}
    assert 5 = Octopus.Eval.eval_string("List.first(args['list'], 5)", args: args)
  end

  test "it allows Enum module" do
    args = %{"list" => [1, 2, 3]}
    assert 1 = Octopus.Eval.eval_string("Enum.min(args['list'])", args: args)
    assert 6 = Octopus.Eval.eval_string("Enum.reduce(args['list'], &(&1 + &2))", args: args)
  end

  test "it allows Map module" do
    args = %{"map" => %{"a" => 1, "b" => 2}}
    assert 1 = Octopus.Eval.eval_string("Map.get(args['map'], 'a')", args: args)

    assert ["a", "b"] = Octopus.Eval.eval_string("Map.keys(args['map'])", args: args)
  end

  test "it allows String module" do
    assert 3 = Octopus.Eval.eval_string("String.length(\"abc\")", [])
  end

  test "it allows && and ||" do
    assert true = Octopus.Eval.eval_string("true && true", [])
    assert true = Octopus.Eval.eval_string("false || true", [])
  end

  test "to_string" do
    args = %{"x" => 1}
    assert "1" = Octopus.Eval.eval_string("to_string(args['x'])", args: args)
  end

  test "with variables" do
    args = %{"x" => 1, "y" => 2}
    template = "{args[\"x\"], args[\"y\"], \"path/#{args["x"]}\"}"
    assert Octopus.Eval.eval_string(template, args: args) == {1, 2, "path/1"}
  end

  test "with single quotes" do
    args = %{"foo" => "the_foo"}
    assert "the_foobaz" = Octopus.Eval.eval_string("args['foo'] <> 'baz'", args: args)
  end

  test "eval string without code" do
    assert_raise SyntaxError, fn -> Octopus.Eval.eval_string("my_string", []) end
  end

  test "for non string" do
    assert_raise RuntimeError, "1 is not a string", fn -> Octopus.Eval.eval_string(1, []) end
    assert_raise RuntimeError, fn -> Octopus.Eval.eval_string([2, 3], []) end
    assert_raise RuntimeError, "aaa is not a string", fn -> Octopus.Eval.eval_string(:aaa, []) end
  end

  test "case condition" do
    code = "case args[\"x\"] do
      1 -> true
      2 -> false
    end
    "
    assert Octopus.Eval.eval_string(code, args: %{"x" => 1}) == true
    assert Octopus.Eval.eval_string(code, args: %{"x" => 2}) == false
  end

  test "cond condition" do
    code = "cond do
      args[\"x\"] == 1 -> true
      args[\"x\"] == 2 -> false
      true -> nil
    end
    "
    assert Octopus.Eval.eval_string(code, args: %{"x" => 1}) == true
    assert Octopus.Eval.eval_string(code, args: %{"x" => 2}) == false
    assert Octopus.Eval.eval_string(code, args: %{"x" => 3}) == nil
  end

  test "if and unless conditions" do
    code = "if args[\"x\"] > 0, do: true, else: false"
    assert Octopus.Eval.eval_string(code, args: %{"x" => 1}) == true
    assert Octopus.Eval.eval_string(code, args: %{"x" => -1}) == false
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
             ) == 3

      assert Octopus.Eval.eval_string(
               "mult(args)",
               args: args,
               helpers: [Helpers, OtherHelpers]
             ) == 2
    end
  end
end
