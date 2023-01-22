defmodule OctopusAgent.RequestsTest do
  use ExUnit.Case
  use Plug.Test

  alias OctopusAgent.Router
  alias OctopusAgent.Test.Definitions

  defmodule Client do
    def start(args, configs) do
      {:ok, %{"state" => "here", "args" => args, "configs" => configs}}
    end

    def call(%{"foo" => foo}, _configs, _state) do
      {:ok, %{"bar" => foo <> "baz"}}
    end
  end

  defmodule Adapter do
    def call(args, configs, state) do
      Client.call(args, configs, state)
    end
  end

  @definition Definitions.read_from_octopus_core("example.json")
              |> Jason.decode!()
              |> put_in(["client", "module"], "OctopusAgent.RequestsTest.Client")
              |> put_in(["client", "adapter"], "OctopusAgent.RequestsTest.Adapter")
              |> Jason.encode!()

  describe "define" do
    setup do
      resp =
        :post
        |> conn("/define", @definition)
        |> Router.call(%{})
      %{resp: resp}
    end


    test "post definition and check module", %{resp: resp} do
      assert Jason.decode!(resp.body) == %{"ok" => "example-service"}
      assert apply(Octopus.Services.ExampleService, :ok?, []) == true
    end

    test "start service" do

    end
  end
  
  describe "define with invalid payload" do
    
  end

#
#  alias Octopus.Test.Definitions
#
#  test "cli definition with eval" do
#    definition = Definitions.cli()
#
#    conn =
#      :post
#      |> conn("/define", definition)
#      |> Api.Router.call(%{})
#
#    data = Jason.decode!(conn.resp_body)
#    assert data["code"]
#
#    {:ok, string} = Octopus.Services.Ipcalc.for_ip(%{"ip" => "192.168.0.1"})
#    assert String.contains?(string, "Address:   192.168.0.1")
#
#    conn =
#      :post
#      |> conn("/services/ipcalc/for_ip", %{"ip" => "192.168.0.1"})
#      |> Api.Router.call(%{})
#
#    assert String.contains?(conn.resp_body, "Address:   192.168.0.1")
#
#    conn =
#      :post
#      |> conn("/services/ipcalc/for_ip_with_mask", %{"ip" => "192.168.0.1", "mask" => "24"})
#      |> Api.Router.call(%{})
#
#    assert String.contains?(conn.resp_body, "Address:   192.168.0.1")
#  end
#
#  test "json_api definition with eval" do
#    definition = Definitions.json_api()
#
#    conn =
#      :post
#      |> conn("/define", definition)
#      |> Api.Router.call(%{})
#
#    conn =
#      :post
#      |> conn("/services/agify/age_for_name", %{"name" => "Anton"})
#      |> Api.Router.call(%{})
#
#    result = Jason.decode!(conn.resp_body)
#    assert result["age"] == 56
#  end
#
#  test "json_server definition with eval" do
#    definition = Definitions.json_server()
#
#    conn =
#      :post
#      |> conn("/define", definition)
#      |> Api.Router.call(%{})
#
#    conn =
#      :post
#      |> conn("/services/json_server.v1/post", %{"id" => 1})
#      |> Api.Router.call(%{})
#
#    result = Jason.decode!(conn.resp_body)
#    assert result["id"] == 1
#  end
#
#  test "elixir_module definition with eval" do
#    definition = Definitions.elixir_module()
#
#    conn =
#      :post
#      |> conn("/define", definition)
#      |> Api.Router.call(%{})
#
#    conn =
#      :post
#      |> conn("/services/my_module/hello", %{"name" => "Anton"})
#      |> Api.Router.call(%{})
#
#    assert conn.resp_body == "Hello Anton"
#
#    conn =
#      :post
#      |> conn("/services/my_module/add", %{"x" => 1, "y" => 2})
#      |> Api.Router.call(%{})
#
#    assert conn.resp_body == "3"
#  end
#
#  test "postgres_sql definition with eval" do
#    definition = Definitions.postgres_sql()
#
#    conn =
#      :post
#      |> conn("/define", definition)
#      |> Api.Router.call(%{})
#
#    conn =
#      :post
#      |> conn("/services/postgres_sql/drop_users_table", %{})
#      |> Api.Router.call(%{})
#
#    conn =
#      :post
#      |> conn("/services/postgres_sql/create_users_table", %{})
#      |> Api.Router.call(%{})
#
#    conn =
#      :post
#      |> conn("/services/postgres_sql/insert_user", %{"name" => "Anton", "age" => 123})
#      |> Api.Router.call(%{})
#
#    conn =
#      :post
#      |> conn("/services/postgres_sql/get_user_by_name", %{"name" => "Anton"})
#      |> Api.Router.call(%{})
#
#    result = Jason.decode!(conn.resp_body)
#    assert [[1, "Anton", 123]] = result["rows"]
#  end
end
