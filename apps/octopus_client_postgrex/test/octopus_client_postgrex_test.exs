defmodule OctopusClientPostgrexTest do
  use ExUnit.Case

  @configs %{
    "host" => "localhost",
    "port" => "5432",
    "username" => "postgres",
    "password" => "postgres"
  }

  describe "start" do
    setup do
      args = %{"database" => "octopus_test"}
      {:ok, state} = OctopusClientPostgrex.start(args, @configs, MyService)
      on_exit(fn -> OctopusClientPostgrex.stop(%{}, %{}, state) end)
      %{state: state}
    end

    test "check the state", %{state: state} do
      assert state.name == MyService
      assert state.host == "localhost"
      assert state.port == "5432"
      assert state.database == "octopus_test"
      assert state.username == "postgres"
      assert state.password == "postgres"
    end

    test "start another client" do
      args = %{"database" => "octopus_test", "process_name" => "postgres_client"}
      {:ok, state} = OctopusClientPostgrex.start(args, @configs, MyService)
      assert state.name == :postgres_client
    end
  end

  describe "call" do
    setup do
      args = %{"database" => "octopus_test", "process_name" => "my_postgres_client"}
      {:ok, state} = OctopusClientPostgrex.start(args, @configs, MyService)
      on_exit(fn -> OctopusClientPostgrex.stop(%{}, %{}, state) end)
      %{state: state}
    end

    test "call with query", %{state: state} do
      args = %{
        "statement" => "SELECT * FROM users",
        "params" => [],
        "opts" => []
      }

      {:ok, result} = OctopusClientPostgrex.call(args, %{}, state)
      assert result["columns"] == ["id", "name", "age"]
    end

    test "call with invalid query", %{state: state} do
      args = %{
        "statement" => "INVALID QUERY",
        "params" => [],
        "opts" => []
      }

      {:error, %Postgrex.Error{}} = OctopusClientPostgrex.call(args, %{}, state)
    end
  end
end
