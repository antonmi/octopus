defmodule Octopus.Rpc.UnixCommandTest do
  use ExUnit.Case
  alias Octopus.Rpc.UnixCommand

  describe "define/2" do
    test "define" do
      definition = Octopus.Test.Definitions.unix_command()
      {:ok, _code} = UnixCommand.define(definition)

      {:ok, string} = Octopus.Service.Ipcalc.for_ip(%{"ip" => "192.168.0.1"})
      assert String.contains?(string, "Address:   192.168.0.1")

      {:ok, string} =
        Octopus.Service.Ipcalc.for_ip_with_mask(%{"ip" => "192.168.0.1", "mask" => "24"})

      assert String.contains?(string, "Address:   192.168.0.1")
    end
  end
end
