defmodule OctopusAgentTest do
  use ExUnit.Case
  doctest OctopusAgent

  test "greets the world" do
    assert OctopusAgent.hello() == :world
  end
end
