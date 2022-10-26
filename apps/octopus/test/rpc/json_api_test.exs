defmodule Octopus.Rpc.JsonApiTest do
  use ExUnit.Case
  alias Octopus.Rpc.JsonApi

  describe "define/2" do
    test "define" do
      definition = Octopus.Test.Definitions.json_api()
      {:ok, _code} = JsonApi.define(definition)

      {:ok, map} = Octopus.Service.Agify.age_for_name(%{"name" => "Anton"})
      assert map["age"] == 55
    end
  end
end
