defmodule OctopusTest do
  use ExUnit.Case, async: true
  alias Octopus.Test.Definitions

  defmodule Client do
    def start(args, configs) do
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

  defmodule Adapter do
    def call(args, configs, state) do
      Client.call(args, configs, state)
    end
  end

  @definition Definitions.read_and_decode("example.json")
              |> put_in(["name"], "my-service")
              |> put_in(["client", "module"], "OctopusTest.Client")
              |> put_in(["client", "adapter"], "OctopusTest.Adapter")

  setup_all do
    {:ok, "my-service"} = Octopus.define(@definition)

    :ok
  end

  describe "start/1" do
    test "state" do
      {:ok, state} = Octopus.start("my-service", %{"a" => "b"})

      assert state == %{
               "state" => "here",
               "args" => %{"a" => "b"},
               "configs" => %{"baz" => 10, "foo" => "bar"}
             }
    end

    test "starting non-existent service" do
      assert {:error, "Module 'Elixir.Octopus.Services.NonExistentService' doesn't exist!"} =
               Octopus.start("non-existent-service", %{})
    end

    test "smth went wrong" do
      assert {:error, "oops"} = Octopus.start("my-service", %{"fail" => "oops"})
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
