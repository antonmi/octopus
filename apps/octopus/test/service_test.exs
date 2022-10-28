defmodule Octopus.ServiceTest do
  use ExUnit.Case
  alias Octopus.Service
  alias Octopus.Service.Storage
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
    end
  end
end
