defmodule Octopus.TransformTest do
  use ExUnit.Case, async: true

  alias Octopus.Transform

  describe "transform/2" do
    test "when args are valid" do
      args = %{"foo" => "bar", "baz" => 1, "h" => "haha"}

      config = %{
        "x" => "/path/#{args["foo"]}",
        "y" => [1, "args[\"baz\"]", "args[\"h\"]"],
        "bool" => true,
        "number" => 100_500,
        "null" => nil,
        "params" => %{
          "a" => "args[\"baz\"]",
          "b" => %{"c" => "args[\"foo\"]"},
          "path" => "'/users/' <> args['foo']"
        },
        "headers" => %{"header" => "args[\"h\"]"}
      }

      {:ok, new_args} = Transform.transform(args, config)

      assert new_args == %{
               "bool" => true,
               "headers" => %{"header" => "haha"},
               "null" => nil,
               "number" => 100_500,
               "params" => %{"a" => 1, "b" => %{"c" => "bar"}, "path" => "/users/bar"},
               "x" => "/path/bar",
               "y" => [1, 1, "haha"]
             }
    end

    test "with Access module" do
      args = %{"list" => [1, 2, 3]}
      config = %{"second" => "get_in(args['list'], [Access.at(1)])"}
      assert {:ok, %{"second" => 2}} = Transform.transform(args, config)
    end

    test "with config == false" do
      args = %{"foo" => "bar", "baz" => 1, "h" => "haha"}
      assert {:ok, ^args} = Transform.transform(args, false)
    end
  end

  describe "transform/2 with custom helper module" do
    defmodule MyCustomHelpers do
      def inc_by_one(number), do: number + 1
    end

    test "use of the helper" do
      args = %{"foo" => 1}

      config = %{
        "bar" => "inc_by_one(args['foo'])"
      }

      {:ok, new_args} = Transform.transform(args, config, [__MODULE__.MyCustomHelpers])
      assert new_args == %{"bar" => 2}
    end
  end
end
