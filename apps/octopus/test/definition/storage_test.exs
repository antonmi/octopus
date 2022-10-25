defmodule Octopus.Definition.StorageTest do
  use ExUnit.Case
  alias Octopus.Definition.Storage

  @command_definition %{
    type: "command",
    name: "ipcalc",
    command: "/usr/local/bin/ipcalc"
  }

  test "add and get" do
    Storage.add(@command_definition)
    assert Storage.get("ipcalc") == @command_definition
  end
end
