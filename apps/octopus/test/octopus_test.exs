defmodule OctopusTest do
  use ExUnit.Case, async: true
  alias Octopus.Test.Definitions

  defmodule Client do
    def init(args, configs) do
      if args["fail"] do
        raise args["fail"]
      end

      {:ok, %{"state" => "here", "args" => args, "configs" => configs}}
    end

    def call(%{"foo" => foo}, _configs, _state) do
      if foo == "fail" do
        raise "fail"
      end

      {:ok, %{"bar" => foo <> "baz"}}
    end
  end

  @definition Definitions.read_and_decode("example.json")
              |> put_in(["name"], "my-service")
              |> put_in(["client", "module"], "OctopusTest.Client")

  setup_all do
    {:ok, "my-service"} = Octopus.define(@definition)

    :ok
  end

  describe "init/1" do
    test "state" do
      {:ok, state} = Octopus.init("my-service", %{"a" => "b"})

      assert state == %{
               "state" => "here",
               "args" => %{"a" => "b"},
               "configs" => %{"baz" => 10, "foo" => "bar"}
             }
    end

    test "starting non-existent service" do
      assert {:error, "Module 'Elixir.Octopus.Services.NonExistentService' doesn't exist!"} =
               Octopus.init("non-existent-service", %{})
    end

    test "smth went wrong" do
      assert {:error, "oops"} = Octopus.init("my-service", %{"fail" => "oops"})
    end
  end

  describe "call" do
    test "my_function/1" do
      {:ok, result} = Octopus.call("my-service", "my_function", %{"in" => "in"})
      assert result == %{"out" => "inbaz"}
    end

    test "smth went wrong" do
      assert {:error, "fail"} = Octopus.call("my-service", "my_function", %{"in" => "fail"})
    end
  end
end
