defmodule AnotherLambdaModule do
  def hello(%{"name" => name}) do
    "Hello #{name}"
  end

  def add(%{"x" => x, "y" => y}), do: x + y
end

defmodule AnotherLambdaModule2 do
  def hello(%{"name" => name}) do
    "Hello " <> name <> "!!!"
  end
end

defmodule Octopus.LambdaTest do
  use ExUnit.Case, async: true
  alias Octopus.Definition

  def parse_definition() do
    Octopus.Test.Definitions.read_and_decode("lambda_example.json")
  end

  setup do
    on_exit(fn ->
      Octopus.delete("lambda-service")
      Octopus.delete("another-lambda-service")
    end)
  end

  @service_module Octopus.Services.LambdaService

  describe "when code provided in the definition" do
    test "define and test elixir module" do
      definition_map = parse_definition()

      definition = Definition.new(definition_map)
      Definition.define(definition)
      {:ok, _code} = apply(@service_module, :start, [])

      code = apply(@service_module, :state, [])
      assert is_binary(code)

      assert apply(AnotherLambdaModule, :hello, [%{"name" => "world"}]) == "Hello world"

      {:ok, result} = apply(@service_module, :hello, [%{"name" => "world"}])
      assert result == %{"greeting" => "Hello world"}

      {:ok, result} = apply(@service_module, :add_numbers, [%{"x" => 1, "y" => 2}])
      assert result == %{"result" => 3}
    end

    test "start with custom code" do
      definition_map =
        parse_definition()
        |> put_in(["name"], "another-lambda-service")
        |> put_in(["interface", "hello", "call", "module"], "AnotherLambdaModule3")

      definition = Definition.new(definition_map)
      Definition.define(definition)

      start_args = %{
        "code" => """
          defmodule AnotherLambdaModule3 do
            def hello(%{"name" => name}) do
              "Hello " <> name <> "!!!"
            end
          end
        """
      }

      service_module = Octopus.Services.AnotherLambdaService

      {:ok, _code} = apply(service_module, :start, [start_args])
      {:ok, result} = apply(service_module, :hello, [%{"name" => "world"}])
      assert result == %{"greeting" => "Hello world!!!"}
    end
  end

  describe "when module provided in the definition" do
    test "define and test elixir module" do
      definition_map =
        put_in(parse_definition(), ["client", "start"], %{"module" => "AnotherLambdaModule"})

      definition = Definition.new(definition_map)
      Definition.define(definition)
      {:ok, _code} = apply(@service_module, :start, [])

      module = apply(@service_module, :state, [])
      assert is_atom(module)

      assert apply(AnotherLambdaModule, :hello, [%{"name" => "world"}]) == "Hello world"

      {:ok, result} = apply(@service_module, :hello, [%{"name" => "world"}])
      assert result == %{"greeting" => "Hello world"}

      {:ok, result} = apply(@service_module, :add_numbers, [%{"x" => 1, "y" => 2}])
      assert result == %{"result" => 3}
    end

    test "start with custom module" do
      definition_map =
        parse_definition()
        |> put_in(["name"], "another-lambda-service")
        |> put_in(["client", "start"], %{"module" => "AnotherLambdaModule2"})

      definition = Definition.new(definition_map)
      Definition.define(definition)

      start_args = %{"module" => "AnotherLambdaModule2"}

      service_module = Octopus.Services.AnotherLambdaService

      {:ok, _code} = apply(service_module, :start, [start_args])
      {:ok, result} = apply(service_module, :hello, [%{"name" => "world"}])
      assert result == %{"greeting" => "Hello world!!!"}
    end
  end

  test "error when both code and module are provided" do
    start = %{"module" => "AnotherLambdaModule", "code" => "code"}
    definition_map = put_in(parse_definition(), ["client", "start"], start)
    definition = Definition.new(definition_map)
    Definition.define(definition)

    assert {:error, "Ether \"code\" or \"module\" must be provided"} =
             apply(@service_module, :start, [])
  end
end
