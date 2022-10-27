defmodule Octopus.Interface.JsonApiTest do
  use ExUnit.Case
  alias Octopus.Interface.JsonApi

  describe "json_api payload" do
    test "define and call" do
      definition = Octopus.Test.Definitions.json_api()
      {:ok, _code} = JsonApi.define(definition["name"], definition["interface"])

      {:ok, map} = Octopus.Service.Agify.age_for_name(%{"name" => "Anton"})
      assert map["age"] == 55
    end
  end
end
