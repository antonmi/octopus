defmodule Octopus.ElixirModuleExampleTest do
  use ExUnit.Case, async: true
  alias Octopus.Definition

  def parse_definition() do
    path = Path.expand("..", __ENV__.file)

    "#{path}/elixir_module_example.json"
    |> File.read!()
    |> Jason.decode!()
  end

  @service_module Octopus.Services.ElixirModuleService

  test "define and test elixir module" do
    definition_map = parse_definition()
    definition = Definition.new(definition_map)
    Definition.define(definition)
    {:ok, _code} = apply(@service_module, :start, [])

    assert apply(TheModule, :hello, [%{"name" => "world"}]) == "Hello world"

    {:ok, result} = apply(@service_module, :hello, [%{"name" => "world"}])
    assert result == %{"greeting" => "Hello world"}

    {:ok, result} = apply(@service_module, :add_numbers, [%{"x" => 1, "y" => 2}])
    assert result == %{"result" => 3}
  end

  test "start with custom code" do
    definition_map =
      parse_definition()
      |> put_in(["name"], "another-service")
      |> put_in(["interface", "hello", "call", "module"], "TheModule2")

    definition = Definition.new(definition_map)
    Definition.define(definition)

    start_args = %{
      "code" => """
        defmodule TheModule2 do
          def hello(%{"name" => name}) do
            "Hello " <> name <> "!!!"
          end
        end
      """
    }

    service_module = Octopus.Services.AnotherService

    {:ok, _code} = apply(service_module, :start, [start_args])
    {:ok, result} = apply(service_module, :hello, [%{"name" => "world"}])
    assert result == %{"greeting" => "Hello world!!!"}
  end
end
