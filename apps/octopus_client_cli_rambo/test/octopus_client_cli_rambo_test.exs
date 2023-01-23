defmodule OctopusClientCliRamboTest do
  use ExUnit.Case, async: true

  def parse_definition() do
    path = Path.expand("../definitions", __ENV__.file)

    "#{path}/files.json"
    |> File.read!()
    |> Jason.decode!()
  end

  setup_all do
    {:ok, "files"} = Octopus.define(parse_definition())
    {:ok, _state} = Octopus.start("files")

    :ok
  end

  test "ls" do
    {:ok, result} = Octopus.call("files", "ls", %{"path" => ".."})
    assert result["status"] == 0
    assert Enum.member?(result["output"], "octopus_core")
  end
end
