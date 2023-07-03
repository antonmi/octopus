defmodule Octopus.AgifyServiceTest do
  use ExUnit.Case, async: true

  def read_definition() do
    path = Path.expand("../definitions", __ENV__.file)

    File.read!("#{path}/agify.json")
  end

  setup do
    {:ok, "agify"} = Octopus.define(read_definition())
    {:ok, _state} = Octopus.start("agify")

    on_exit(fn -> Octopus.delete("agify") end)
  end

  test "age_for_name" do
    assert {:ok, %{"age" => 69, "name" => "bob", "status" => 200, "x-request-id" => _request_id}} =
             Octopus.call("agify", "age_for_name", %{"name" => "bob"})
  end
end
