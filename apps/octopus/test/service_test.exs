defmodule Octopus.ServiceTest do
  use ExUnit.Case
  alias Octopus.Service
  alias Octopus.Test.Definitions

  describe "define" do
    test "define unix_command and call it" do
      definition = Definitions.unix_command()
      {:ok, _code} = Service.define(definition)

      {:ok, string} = Octopus.Service.Ipcalc.for_ip(%{"ip" => "192.168.0.1"})
      assert String.contains?(string, "Address:   192.168.0.1")

      assert Octopus.Definition.Storage.get("ipcalc") == definition

      {:ok, string} = Service.call("ipcalc", "for_ip", %{"ip" => "192.168.0.1"})
      assert String.contains?(string, "Address:   192.168.0.1")
    end
  end
end
