defmodule OctopusClientCliRamboTest do
  use ExUnit.Case, async: true

  def read_definition() do
    path = Path.expand("../definitions", __ENV__.file)

    File.read!("#{path}/files.json")
  end

  setup_all do
    {:ok, "files"} = Octopus.define(read_definition())
    {:ok, _state} = Octopus.init("files")

    :ok
  end

  test "ls" do
    {:ok, result} = Octopus.call("files", "ls", %{"path" => ".."})
    assert result["status"] == 0
    assert Enum.member?(result["output"], "octopus")
  end
end
