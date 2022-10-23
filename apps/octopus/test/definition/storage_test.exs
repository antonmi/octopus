defmodule Octopus.Definition.StorageTest do
  use ExUnit.Case
  alias Octopus.Definition.Storage

  @cli_definition %{
    type: "cli",
    name: "ipcalc",
    command: "/usr/local/bin/ipcalc",
    request: %{
      method: "POST",
      path: "/services/ipcalc",
      # json #number
      payload: :text
    }
  }

  test "add and get" do
    Storage.add(@cli_definition)
    assert Storage.get("ipcalc") == @cli_definition
  end
end
