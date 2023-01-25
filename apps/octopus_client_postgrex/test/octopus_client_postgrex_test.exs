defmodule OctopusClientPostgrexTest do
  use ExUnit.Case

  @configs %{
    "host" => "localhost",
    "port" => "5432",
    "username" => "postgres",
    "password" => "postgres"
  }

  describe "init" do
    setup do
      args = %{"database" => "octopus_test", "process_name" => "postgres_client"}
      {:ok, state} = OctopusClientPostgrex.init(args, @configs)
      %{state: state}
    end

    test "check the state", %{state: state} do
      assert state.name == :postgres_client
      assert state.host == "localhost"
      assert state.port == "5432"
      assert state.database == "octopus_test"
      assert state.username == "postgres"
      assert state.password == "postgres"
    end

    test "init another client" do
      args = %{"database" => "octopus_test", "process_name" => "postgres_client2"}
      {:ok, state} = OctopusClientPostgrex.init(args, @configs)
      assert state.name == :postgres_client2
    end
  end

  describe "call" do
    setup do
      args = %{"database" => "octopus_test", "process_name" => "my_postgres_client"}
      {:ok, state} = OctopusClientPostgrex.init(args, @configs)
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

      {:error, %OctopusClientPostgrex.Error{}} = OctopusClientPostgrex.call(args, %{}, state)
    end
  end
end
