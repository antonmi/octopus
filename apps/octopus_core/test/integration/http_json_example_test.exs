defmodule Octopus.HttpJsonExampleTest do
  use ExUnit.Case, async: true
  alias Octopus.Definition

  def parse_definition() do
    path = Path.expand("..", __ENV__.file)

    "#{path}/http_json_example.json"
    |> File.read!()
    |> Jason.decode!()
  end

  @service_module Octopus.Services.Agify

  test "definition" do
    definition_map = parse_definition()
    definition = Definition.new(definition_map)
    Definition.define(definition)

    assert apply(@service_module, :ok?, [])

    # start without args
    assert {:ok, _state} = apply(@service_module, :start, [])
    # start with args
    assert {:ok, _state} = apply(@service_module, :start, [definition_map["client"]["start"]])

    assert {:ok, %{"age" => 69, "name" => "bob", "status" => 200, "x-request-id" => _request_id}} =
             apply(@service_module, :age_for_name, [%{"name" => "bob"}])
  end
end
