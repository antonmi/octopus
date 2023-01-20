defmodule Octopus.CallTest do
  use ExUnit.Case, async: true

  alias Octopus.Call

  defmodule Adapter do
    def call(args, configs, _state) do
      if configs["ok"] do
        {:ok, %{"foo" => args["foo"] <> "bar", "baz" => 1}}
      else
        {:error, :some_error}
      end
    end
  end

  @interface_configs %{
    "input" => %{
      "foo" => %{"type" => "string"}
    },
    "prepare" => %{
      "foo" => "args['foo'] <> 'baz'"
    },
    "call" => %{
      "ok" => true
    },
    "transform" => %{
      "x" => "args['foo'] <> 'xxx'",
      "y" => "args['baz'] + 1"
    },
    "output" => %{
      "x" => %{"type" => "string"},
      "y" => %{"type" => "integer"}
    }
  }

  describe "call/3 success case" do
    test "success" do
      args = %{"foo" => "the_foo"}
      {:ok, result} = Call.call(Adapter, args, @interface_configs, %{})
      assert result == %{"x" => "the_foobazbarxxx", "y" => 2}
    end
  end

  describe "error cases" do
    test "when input has invalid type" do
      args = %{"foo" => 1}
      {:error, error} = Call.call(Adapter, args, @interface_configs, %{})
      assert error == [{"Type mismatch. Expected String but got Integer.", "#/foo"}]
    end

    test "when input doesn't have required field" do
      interface_configs = put_in(@interface_configs["input"]["required"], ["foo"])

      {:error, error} = Call.call(Adapter, %{}, interface_configs, %{})
      assert error == [{"Required property foo was not present.", "#"}]
    end

    test "when input has invalid configs" do
      interface_configs = put_in(@interface_configs["input"]["required"], 123)

      assert_raise(
        ExJsonSchema.Schema.InvalidSchemaError,
        fn -> Call.call(Adapter, %{}, interface_configs, %{}) end
      )
    end

    test "error in output" do
      interface_configs = put_in(@interface_configs["transform"]["y"], "to_string(args['baz'])")
      {:error, error} = Call.call(Adapter, %{"foo" => "the_foo"}, interface_configs, %{})
      assert error == [{"Type mismatch. Expected Integer but got String.", "#/y"}]
    end

    test "error in adapter call" do
      interface_configs = put_in(@interface_configs["call"]["ok"], false)

      assert {:error, :some_error} =
               Call.call(Adapter, %{"foo" => "the_foo"}, interface_configs, %{})
    end
  end
end
