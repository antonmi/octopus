defmodule Octopus.Service.StorageTest do
  use ExUnit.Case
  alias Octopus.Service.Storage

  @definition %{
    "type" => "command",
    "name" => "ipcalc"
  }

  test "add and get" do
    Storage.add(@definition)
    assert Storage.get("ipcalc") == @definition
  end
end
