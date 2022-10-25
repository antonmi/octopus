defmodule Octopus.Definition.StorageTest do
  use ExUnit.Case
  alias Octopus.Definition.Storage

  @cli_definition %{
    type: "command",
    name: "ipcalc",
    command: "/usr/local/bin/ipcalc"
  }

  test "add and get" do
    Storage.add(@cli_definition)
    assert Storage.get("ipcalc") == @cli_definition
  end
end
