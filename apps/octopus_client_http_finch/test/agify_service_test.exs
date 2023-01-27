defmodule Octopus.AgifyServiceTest do
  use ExUnit.Case, async: true

  def read_definition() do
    path = Path.expand("../definitions", __ENV__.file)

    File.read!("#{path}/agify.json")
  end

  setup_all do
    {:ok, "agify"} = Octopus.define(read_definition())
    {:ok, _state} = Octopus.init("agify")

    :ok
  end

  test "try to init the same service" do
    assert {:error, :already_started} = Octopus.init("agify")
  end

  test "age_for_name" do
    assert {:ok, %{"age" => 69, "name" => "bob", "status" => 200, "x-request-id" => _request_id}} =
             Octopus.call("agify", "age_for_name", %{"name" => "bob"})
  end

  test "stop client" do
    {:ok, %{name: Octopus.Services.Agify}} = Octopus.stop("agify")
    assert {:error, "Service not initiated!"} = Octopus.stop("agify")
  end
end
