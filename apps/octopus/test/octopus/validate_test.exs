defmodule Octopus.ValidateTest do
  use ExUnit.Case, async: true

  alias Octopus.Validate

  describe "validate/2" do
    @schema %{
      "type" => "object",
      "properties" => %{
        "foo" => %{"type" => "string"},
        "baz" => %{"type" => "number"},
        "bool" => %{"type" => "boolean"}
      }
    }

    test "when args are valid" do
      args = %{"foo" => "bar", "baz" => 1, "bool" => true}
      assert {:ok, ^args} = Validate.validate(args, @schema)
    end

    test "it accepts schema without 'type'" do
      args = %{"foo" => "bar", "baz" => 1, "bool" => true}
      schema = %{"properties" => @schema["properties"]}
      assert {:ok, ^args} = Validate.validate(args, schema)
    end

    test "when args are invalid" do
      args = %{"foo" => 2}
      {:error, error} = Validate.validate(args, @schema)
      assert error.message == "#/foo:Type mismatch. Expected String but got Integer."
    end

    test "it accepts schema without 'properties'" do
      args = %{"foo" => 2}
      schema = %{"foo" => %{"type" => "string"}}
      {:error, error} = Validate.validate(args, schema)
      assert error.message == "#/foo:Type mismatch. Expected String but got Integer."
    end

    test "it handles the 'required' field" do
      args = %{"foo" => "bar"}
      schema = Map.merge(@schema["properties"], %{"required" => ["foo", "baz"]})
      {:error, error} = Validate.validate(args, schema)
      assert error.message =~ "Required property baz was not present."
    end
  end
end
