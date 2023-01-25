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

  @definition Definitions.read_from_octopus_core("example.json")
              |> Jason.decode!()
              |> put_in(["client", "module"], "OctopusAgent.RequestsTest.Client")
              |> Jason.encode!()

  describe "define" do
    setup do
      conn =
        :post
        |> conn("/define", @definition)
        |> Router.call(%{})

      %{conn: conn}
    end

    test "post definition and check module", %{conn: conn} do
      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"ok" => "example-service"}
      assert apply(Octopus.Services.ExampleService, :ok?, []) == true
    end

    test "incorrect definition" do
      payload =
        @definition
        |> Jason.decode!()
        |> put_in(["client", "module"], "NoSuchModule")
        |> Jason.encode!()

      conn =
        :post
        |> conn("/define", payload)
        |> Router.call(%{})

      assert conn.status == 400
      assert Jason.decode!(conn.resp_body) == %{"error" => "Module 'NoSuchModule' doesn't exist!"}
    end

    test "start and call service" do
      conn =
        :post
        |> conn("/start/example-service", Jason.encode!(%{"a" => "b"}))
        |> Router.call(%{})

      assert conn.status == 200

      assert Jason.decode!(conn.resp_body) == %{
               "args" => %{"a" => "b"},
               "configs" => %{"baz" => 10, "foo" => "bar"},
               "state" => "here"
             }

      conn =
        :post
        |> conn("/services/example-service/my_function", Jason.encode!(%{"in" => "in"}))
        |> Router.call(%{})

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"out" => "inbaz"}
    end
  end
end
