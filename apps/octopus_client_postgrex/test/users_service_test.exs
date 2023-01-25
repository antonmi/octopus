defmodule OctopusClientPostgrex.UsersServiceTest do
  use ExUnit.Case, async: true

  def read_definition() do
    path = Path.expand("../definitions", __ENV__.file)

    File.read!("#{path}/users.json")
  end

  setup_all do
    {:ok, "users"} = Octopus.define(read_definition())
    {:ok, _state} = Octopus.init("users")

    :ok
  end

  test "all" do
    {:ok, result} = Octopus.call("users", "all", %{})

    assert %{
             "columns" => _,
             "num_rows" => _,
             "rows" => _
           } = result
  end

  test "insert and find" do
    {:ok, %{"id" => id}} = Octopus.call("users", "insert", %{"name" => "bob", "age" => 69})
    {:ok, result} = Octopus.call("users", "find", %{"id" => id})
    assert %{"age" => 69, "id" => ^id, "name" => "bob"} = result
  end
end
