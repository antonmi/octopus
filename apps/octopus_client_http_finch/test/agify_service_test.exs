defmodule Octopus.AgifyServiceTest do
  use ExUnit.Case, async: true

  def parse_definition() do
    path = Path.expand("../definitions", __ENV__.file)

    "#{path}/agify.json"
    |> File.read!()
    |> Jason.decode!()
  end

  setup_all do
    {:ok, "agify"} = Octopus.define(parse_definition())
    {:ok, _state} = Octopus.start("agify")

    :ok
  end

  test "age_for_name" do
    assert {:ok, %{"age" => 69, "name" => "bob", "status" => 200, "x-request-id" => _request_id}} =
             Octopus.call("agify", "age_for_name", %{"name" => "bob"})
  end
end
