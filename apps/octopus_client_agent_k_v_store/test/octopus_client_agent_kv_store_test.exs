defmodule OctopusClientAgentKVStoreTest do
  use ExUnit.Case, async: true

  describe "start/1" do
    setup do
      {:ok, state} = OctopusClientAgentKVStore.start(%{}, %{}, MyService)
      on_exit(fn -> OctopusClientAgentKVStore.stop(%{}, %{}, state) end)
      %{state: state}
    end

    test "check state and data", %{state: state} do
      assert %{name: MyService, pid: _pid} = state
      assert Agent.get(state.name, fn map -> map end) == %{}
    end

    test "when already started" do
      assert {:error, :already_started} = OctopusClientAgentKVStore.start(%{}, %{}, MyService)
    end

    test "start another service" do
      {:ok, state} = OctopusClientAgentKVStore.start(%{}, %{}, AnotherService)

      assert Agent.get(state.name, fn map -> map end) == %{}
    end
  end

  describe "call" do
    setup do
      {:ok, state} = OctopusClientAgentKVStore.start(%{}, %{}, MyService)
      on_exit(fn -> OctopusClientAgentKVStore.stop(%{}, %{}, state) end)
      %{state: state}
    end

    test "set and get", %{state: state} do
      args = %{"operation" => "set", "key" => "foo", "value" => "bar"}
      assert {:ok, "ok"} = OctopusClientAgentKVStore.call(args, %{}, state)

      args = %{"operation" => "get", "key" => "foo"}
      assert {:ok, "bar"} = OctopusClientAgentKVStore.call(args, %{}, state)
    end

    test "getset", %{state: state} do
      args = %{"operation" => "getset", "key" => "foo", "value" => "bar"}
      assert {:ok, nil} = OctopusClientAgentKVStore.call(args, %{}, state)

      assert {:ok, "bar"} =
               OctopusClientAgentKVStore.call(%{"operation" => "get", "key" => "foo"}, %{}, state)
    end

    test "invalid_operation_or_missing_arguments", %{state: state} do
      assert {:error, :invalid_operation_or_missing_arguments} =
               OctopusClientAgentKVStore.call(%{"operation" => "invalid"}, %{}, state)

      assert {:error, :invalid_operation_or_missing_arguments} =
               OctopusClientAgentKVStore.call(%{"operation" => "get"}, %{}, state)

      assert {:error, :invalid_operation_or_missing_arguments} =
               OctopusClientAgentKVStore.call(
                 %{"operation" => "getset", "key" => "foo"},
                 %{},
                 state
               )

      assert {:error, :invalid_operation_or_missing_arguments} =
               OctopusClientAgentKVStore.call(%{"operation" => "set", "key" => "foo"}, %{}, state)
    end
  end
end
