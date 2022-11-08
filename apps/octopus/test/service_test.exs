defmodule Octopus.ServiceTest do
  use ExUnit.Case
  alias Octopus.Service
  alias Octopus.Test.Definitions

  describe "define" do
    test "define cli and call it" do
      definition = Definitions.cli()
      {:ok, _code} = Service.define(definition)

      {:ok, string} = Octopus.Service.Ipcalc.for_ip(%{"ip" => "192.168.0.1"})
      assert String.contains?(string, "Address:   192.168.0.1")

      {:ok, string} = Service.call("ipcalc", "for_ip", %{"ip" => "192.168.0.1"})
      assert String.contains?(string, "Address:   192.168.0.1")
    end

    test "define json_api and call it" do
      definition = Definitions.json_api()
      {:ok, _code} = Service.define(definition)

      {:ok, map} = Octopus.Service.Agify.age_for_name(%{"name" => "Anton"})
      assert map["age"] == 55
    end

    test "define json_server and call" do
      definition = Definitions.json_server()
      {:ok, _code} = Service.define(definition)

      {:ok, list} = Octopus.Service.JsonServer.V1.posts(%{})
      assert length(list) > 0

      {:ok, map} = Octopus.Service.JsonServer.V1.post(%{"id" => 1})
      assert map["id"] == 1
    end

    test "define elixir_module and call" do
      definition = Definitions.elixir_module()
      {:ok, _code} = Service.define(definition)

      {:ok, greeting} = Octopus.Service.MyModule.hello(%{"name" => "Anton"})
      assert greeting == "Hello Anton"

      {:ok, result} = Octopus.Service.MyModule.add(%{"x" => 1, "y" => 2})
      assert result == 3

      {:ok, result} = Octopus.Service.MyModule.string_length(%{"string" => "Hello"})
      assert result == 5
    end

    test "define postgres_sql and call" do
      definition = Definitions.postgres_sql()
      {:ok, _code} = Service.define(definition)

      Octopus.Service.PostgresSql.drop_users_table(%{})

      {:ok, _result} = Octopus.Service.PostgresSql.create_users_table(%{})

      {:ok, _result} =
        Octopus.Service.PostgresSql.insert_user(%{"name" => "Anton", "age" => "123"})

      {:ok, result} = Octopus.Service.PostgresSql.list_users(%{})
      assert length(result[:rows]) > 0

      {:ok, result} = Octopus.Service.PostgresSql.get_user_by_name(%{"name" => "Anton"})
      assert [_id, "Anton", 123] = hd(result[:rows])
    end

    test "define xml_api and call" do
      definition = Definitions.xml_api()
      {:ok, _code} = Service.define(definition)

      {:ok, [record | _]} = Octopus.Service.Adequateshop.get_travelers(%{"page" => 1})
      assert %{adderes: _, createdat: _, email: _, id: _, name: _} = record

      random_string = for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>
      email = "anton@#{random_string}.com"

      {:ok, record} =
        Octopus.Service.Adequateshop.create_traveler(%{
          "name" => "Anton",
          "email" => email,
          "adderes" => "Germany"
        })

      assert %{adderes: _, createdat: _, email: _, id: id, name: 'Anton'} = record

      {:ok, record} = Octopus.Service.Adequateshop.get_traveler(%{"id" => "#{id}"})
      assert %{adderes: _, createdat: _, email: _, id: _, name: 'Anton'} = record
    end
  end
end
