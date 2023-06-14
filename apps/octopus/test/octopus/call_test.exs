defmodule Octopus.CallTest do
  use ExUnit.Case, async: true

  alias Octopus.{Call, CallError}

  defmodule Client do
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
      struct = %Call{client_module: Client, args: args, interface_configs: @interface_configs}
      {:ok, result} = Call.call(struct)
      assert result == %{"x" => "the_foobazbarxxx", "y" => 2}
    end
  end

  describe "error cases" do
    test "when input has invalid type" do
      args = %{"foo" => 1}
      struct = %Call{client_module: Client, args: args, interface_configs: @interface_configs}
      {:error, %CallError{} = error} = Call.call(struct)
      assert error.type == :input
      assert error.message =~ "Type mismatch."
    end

    test "when input doesn't have required field" do
      interface_configs = put_in(@interface_configs["input"]["required"], ["foo"])
      struct = %Call{client_module: Client, args: %{}, interface_configs: interface_configs}
      {:error, %CallError{} = error} = Call.call(struct)
      assert error.type == :input
      assert error.message =~ "Required property foo was not present"
    end

    test "when input has invalid configs" do
      interface_configs = put_in(@interface_configs["input"]["required"], 123)
      struct = %Call{client_module: Client, args: %{}, interface_configs: interface_configs}

      {:error, %CallError{} = error} = Call.call(struct)
      assert error.type == :input
      assert error.message =~ "schema did not pass validation"
    end

    test "error in output" do
      interface_configs = put_in(@interface_configs["transform"]["y"], "to_string(args['baz'])")

      struct = %Call{
        client_module: Client,
        args: %{"foo" => "the_foo"},
        interface_configs: interface_configs
      }

      {:error, %CallError{} = error} = Call.call(struct)
      assert error.type == :output
      assert error.message =~ "Type mismatch. Expected Integer but got String."
    end

    test "error in adapter call" do
      interface_configs = put_in(@interface_configs["call"]["ok"], false)

      struct = %Call{
        client_module: Client,
        args: %{"foo" => "the_foo"},
        interface_configs: interface_configs
      }

      {:error, %CallError{} = error} = Call.call(struct)
      assert error.type == :call
      assert error.message == ":some_error"
    end
  end
end
