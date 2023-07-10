defmodule OctopusClientHttpFinch.ErrorServiceTest do
  use ExUnit.Case, async: true

  def read_definition() do
    path = Path.expand("../definitions", __ENV__.file)

    File.read!("#{path}/error-service.json")
  end

  def define_and_start_service(definition) do
    {:ok, "error-service"} = Octopus.define(definition)
    {:ok, _state} = Octopus.start("error-service")
  end

  setup do
    on_exit(fn -> Octopus.delete("error-service") end)
  end

  test "call" do
    define_and_start_service(read_definition())
    assert {:ok, result} = Octopus.call("error-service", "do_call", %{})
    assert result == %{"error" => true, "message" => "non-existing domain"}
  end

  test "when there is client error" do
    read_definition()
    |> Jason.decode!()
    |> put_in(["interface", "do_call", "error"], nil)
    |> define_and_start_service()

    assert {:error,
            %Octopus.CallError{
              step: :call,
              error: %Mint.TransportError{reason: :nxdomain},
              message: "non-existing domain",
              stacktrace: stacktrace
            }} = Octopus.call("error-service", "do_call", %{})
    assert is_binary(stacktrace)
  end
end
