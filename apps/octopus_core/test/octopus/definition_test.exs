defmodule Octopus.DefinitionTest do
  use ExUnit.Case, async: true

  alias Octopus.Definition
  alias Octopus.Test.Definitions

  defmodule Client do
    def start(args, configs) do
      {:ok, %{"state" => "here", "args" => args, "configs" => configs}}
    end

    def call(%{"foo" => foo}, _configs, _state) do
      {:ok, %{"bar" => foo <> "baz"}}
    end
  end

  defmodule Adapter do
    def call(args, configs, state) do
      Client.call(args, configs, state)
    end
  end

  @definition Definitions.read_and_decode("example.json")
              |> put_in(["client", "module"], "Octopus.DefinitionTest.Client")
              |> put_in(["client", "adapter"], "Octopus.DefinitionTest.Adapter")

  @service_module Octopus.Services.ExampleService

  setup_all do
    {:ok, "example-service"} =
      @definition
      |> Definition.new()
      |> Definition.define()

    :ok
  end

  test "module is compiled" do
    assert apply(@service_module, :ok?, [])
  end

  describe "start/1" do
    setup do
      {:ok, state} = apply(@service_module, :start, [%{"a" => "b"}])

      %{state: state}
    end

    test "state", %{state: state} do
      assert state == %{
               "state" => "here",
               "args" => %{"a" => "b"},
               "configs" => %{"baz" => 10, "foo" => "bar"}
             }

      assert apply(@service_module, :state, []) == state
    end
  end

  describe "interface" do
    test "my_function/1" do
      {:ok, result} = apply(@service_module, :my_function, [%{"in" => "in"}])
      assert result == %{"out" => "inbaz"}
    end

    test "simple/1" do
      {:ok, result} = apply(@service_module, :simple, [%{"foo" => "foo"}])
      assert result == %{"bar" => "foobaz"}
    end

    test "empty/1" do
      {:ok, result} = apply(@service_module, :empty, [%{"foo" => "foo"}])
      assert result == %{"bar" => "foobaz"}
    end
  end

  describe "invalid definition" do
    test "missing service name" do
      assert_raise Octopus.DefinitionError, "Missing service name!", fn ->
        @definition
        |> Map.delete("name")
        |> Definition.new()
        |> Definition.define()
      end
    end

    test "client module doesn't exist" do
      assert_raise Octopus.DefinitionError, "Module 'Client2' doesn't exist!", fn ->
        @definition
        |> put_in(["client", "module"], "Client2")
        |> Definition.new()
        |> Definition.define()
      end
    end

    test "adapter module doesn't exist" do
      assert_raise Octopus.DefinitionError, "Module 'Nope' doesn't exist!", fn ->
        @definition
        |> put_in(["client", "adapter"], "Nope")
        |> Definition.new()
        |> Definition.define()
      end
    end
  end
end