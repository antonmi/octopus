defmodule OctopusClientAgentKVStore.StoreTest do
  use ExUnit.Case, async: true

  def read_definition(filename) do
    path = Path.expand("../definitions", __ENV__.file)

    File.read!("#{path}/#{filename}")
  end

  setup do
    {:ok, "store"} = Octopus.define(read_definition("store.json"))
    {:ok, _state} = Octopus.start("store")

    on_exit(fn -> Octopus.delete("store") end)
  end

  test "set and get" do
    assert {:ok, %{"ok" => "ok"}} =
             Octopus.call("store", "set", %{"key" => "foo", "value" => "bar"})

    assert {:ok, %{"value" => "bar"}} = Octopus.call("store", "get", %{"key" => "foo"})
  end

  test "getset" do
    assert {:ok, %{"value" => nil}} =
             Octopus.call("store", "getset", %{"key" => "foo", "value" => "bar"})

    assert {:ok, %{"value" => "bar"}} = Octopus.call("store", "get", %{"key" => "foo"})
  end

  describe "error cases" do
    test "wrong operation argument" do
      assert {:error, error} =
               Octopus.call("store", "get_with_wrong_operation", %{"key" => "foo"})

      assert error.step == :call
      assert error.error == :invalid_operation_or_missing_arguments
    end

    test "missing argument" do
      assert {:error, error} = Octopus.call("store", "set", %{"key" => "foo"})

      assert error.step == :input
      assert error.error == [{"Required property value was not present.", "#"}]
    end
  end

  describe "start another another-store" do
    setup do
      {:ok, "another-store"} = Octopus.define(read_definition("another-store.json"))
      {:ok, _state} = Octopus.start("another-store")

      on_exit(fn -> Octopus.delete("another-store") end)
    end

    test "set and get to both services" do
      assert {:ok, %{"ok" => "ok"}} =
               Octopus.call("store", "set", %{"key" => "foo", "value" => "bar1"})

      assert {:ok, %{"value" => "bar1"}} = Octopus.call("store", "get", %{"key" => "foo"})

      assert {:ok, %{"ok" => "ok"}} =
               Octopus.call("another-store", "set", %{"key" => "foo", "value" => "bar2"})

      assert {:ok, %{"value" => "bar2"}} = Octopus.call("another-store", "get", %{"key" => "foo"})
    end
  end
end
