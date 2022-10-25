defmodule Api.Requests.DefinitionTest do
  use ExUnit.Case
  use Plug.Test

  @cli_definition %{
    type: "command",
    name: "ipcalc",
    command: "/usr/local/bin/ipcalc",
    interface: %{
      for_ip: %{
        input: %{
          args: %{ip: nil},
          transform: ":ip"
        },
        output: :binary
      },
      for_ip_with_mask: %{
        input: %{
          args: %{
            ip: nil,
            mask: nil
          },
          transform: ":ip/:mask"
        }
      }
    }
  }

  test "command definition with eval" do
    conn =
      :post
      |> conn("/define", @cli_definition)
      |> Api.Router.call(%{})

    data = Jason.decode!(conn.resp_body)
    assert data["code"]

    {:ok, string} = Octopus.Service.Ipcalc.for_ip(%{ip: "192.168.0.1"})
    assert String.contains?(string, "Address:   192.168.0.1")

    conn =
      :post
      |> conn("/services/ipcalc/for_ip", %{ip: "192.168.0.1"})
      |> Api.Router.call(%{})

    assert String.contains?(conn.resp_body, "Address:   192.168.0.1")

    conn =
      :post
      |> conn("/services/ipcalc/for_ip_with_mask", %{ip: "192.168.0.1", mask: "24"})
      |> Api.Router.call(%{})

    assert String.contains?(conn.resp_body, "Address:   192.168.0.1")
  end
end
