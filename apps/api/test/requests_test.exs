defmodule Api.Requests.DefinitionTest do
  use ExUnit.Case
  use Plug.Test

  alias Octopus.Test.Definitions

  test "unix_command definition with eval" do
    definition = Definitions.unix_command()

    conn =
      :post
      |> conn("/define", definition)
      |> Api.Router.call(%{})

    data = Jason.decode!(conn.resp_body)
    assert data["code"]

    {:ok, string} = Octopus.Service.Ipcalc.for_ip(%{"ip" => "192.168.0.1"})
    assert String.contains?(string, "Address:   192.168.0.1")

    conn =
      :post
      |> conn("/services/ipcalc/for_ip", %{"ip" => "192.168.0.1"})
      |> Api.Router.call(%{})

    assert String.contains?(conn.resp_body, "Address:   192.168.0.1")

    conn =
      :post
      |> conn("/services/ipcalc/for_ip_with_mask", %{"ip" => "192.168.0.1", "mask" => "24"})
      |> Api.Router.call(%{})

    assert String.contains?(conn.resp_body, "Address:   192.168.0.1")
  end

  test "json_api definition with eval" do
    definition = Definitions.json_api()

    conn =
      :post
      |> conn("/define", definition)
      |> Api.Router.call(%{})

    data = Jason.decode!(conn.resp_body)
    assert data["code"]

    {:ok, map} = Octopus.Service.Agify.age_for_name(%{"name" => "Anton"})
    assert map["age"] == 55

    conn =
      :post
      |> conn("/services/agify/age_for_name", %{"name" => "Anton"})
      |> Api.Router.call(%{})

    result = Jason.decode!(conn.resp_body)
    assert result["age"] == 55
  end

  test "json_server definition with eval" do
    definition = Definitions.json_server()

    conn =
      :post
      |> conn("/define", definition)
      |> Api.Router.call(%{})

    {:ok, map} = Octopus.Service.JsonServer.post(%{"id" => 1})
    assert map["id"] == 1

    conn =
      :post
      |> conn("/services/json_server/post", %{"id" => 1})
      |> Api.Router.call(%{})

    result = Jason.decode!(conn.resp_body)
    assert map["id"] == 1
  end
end