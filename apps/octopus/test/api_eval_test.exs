defmodule Octopus.ApiEvalTest do
  use ExUnit.Case
  alias Octopus.Definition
  alias Octopus.ApiEval

  @cli_definition %{
    type: "cli",
    name: "ipcalc",
    command: "/usr/local/bin/ipcalc",
    request: %{
#      method: "POST", #let this to be default
      path: "/services/ipcalc",
      payload: :text #json #number
    }
  }

  test "cli definition" do
    {:ok, code} = Definition.define(@cli_definition)
    assert {:ok, _string} = Octopus.Service.Ipcalc.call("192.168.0.1")
    assert {:ok, string} = ApiEval.eval("/services/ipcalc", "192.168.0.1")
    assert String.contains?(string, "Address:   192.168.0.1")
  end
end
