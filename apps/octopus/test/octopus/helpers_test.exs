defmodule Octopus.HelpersTest do
  use ExUnit.Case, async: true

  @definition %{
    "name" => "helpers",
    "client" => %{
      "module" => "Octopus.ElixirModuleClient",
      "start" => %{
        "code" => [
          "defmodule ModuleWithAddFunction do",
          "def add(%{\"x\" => x, \"y\" => y}), do: x + y",
          "end"
        ]
      }
    },
    "helpers" => [
      "Octopus.HelpersTest.MyCustomHelpers",
      "Octopus.HelpersTest.AnotherHelpers"
    ],
    "interface" => %{
      "add" => %{
        "prepare" => %{
          "x" => "inc_by_one(args[\"x\"])",
          "y" => "mult_by_two(args[\"y\"])"
        },
        "call" => %{
          "module" => "ModuleWithAddFunction",
          "function" => "add"
        },
        "transform" => %{
          "out" => "dec_by_five(args)"
        }
      }
    }
  }

  defmodule MyCustomHelpers do
    def inc_by_one(number), do: number + 1
    def dec_by_five(number), do: number - 5
  end

  defmodule AnotherHelpers do
    def mult_by_two(number), do: number * 2
  end

  setup do
    Octopus.define(@definition)
    {:ok, _state} = Octopus.start("helpers")
    on_exit(fn -> Octopus.delete("helpers") end)
  end

  test "call" do
    assert {:ok, %{"out" => 1}} = Octopus.call("helpers", "add", %{"x" => 1, "y" => 2})
  end
end
