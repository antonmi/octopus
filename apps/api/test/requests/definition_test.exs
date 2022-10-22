defmodule Api.Requests.DefinitionTest do
  use ExUnit.Case
  use Plug.Test

  @cli_definition %{
    type: "cli",
    name: "ipcalc",
    command: "/usr/local/bin/ipcalc",
    request: %{
      path: "/services/ipcalc",
      payload: :text
    }
  }

  test "cli definition with eval" do
    conn =
      :post
      |> conn("/define", @cli_definition)
      |> Api.Router.call(%{})

    data = Jason.decode!(conn.resp_body)
    assert data["code"]

    assert {:ok, string} = Octopus.Service.Ipcalc.call("192.168.0.1")
    assert String.contains?(string, "Address:   192.168.0.1")

    conn =
      :post
      |> conn("/services/ipcalc", "192.168.0.1")
      |> Api.Router.call(%{})

    assert String.contains?(conn.resp_body, "Address:   192.168.0.1")
  end
end
