defmodule OctopusAgent.RequestsTest do
  use ExUnit.Case
  use Plug.Test

  alias OctopusAgent.Router
  alias OctopusAgent.Test.Definitions

  defmodule Client do
    def start(args, configs, _service_name) do
      {:ok, %{"state" => "here", "args" => args, "configs" => configs}}
    end

    def call(%{"foo" => foo}, _configs, _state) do
      {:ok, %{"bar" => foo <> "baz"}}
    end

    def stop(_args, _configs, _state) do
      :ok
    end
  end

  @definition Definitions.read_from_octopus("example.json")
              |> Jason.decode!()
              |> put_in(["name"], "my-service")
              |> put_in(["client", "module"], "OctopusAgent.RequestsTest.Client")
              |> Jason.encode!()

  setup do
    on_exit(fn ->
      OctopusAgent.delete("my-service")
    end)
  end

  describe "define" do
    test "success" do
      conn =
        :post
        |> conn("/define", @definition)
        |> Router.call(%{})

      assert conn.resp_body == "{\"ok\":\"my-service\"}"
    end

    test "error" do
      definition =
        @definition
        |> Jason.decode!()
        |> put_in(["name"], nil)
        |> Jason.encode!()

      conn =
        :post
        |> conn("/define", definition)
        |> Router.call(%{})

      assert String.contains?(conn.resp_body, "Missing service name!")
    end
  end

  describe "status" do
    setup do
      OctopusAgent.define(@definition)
      :ok
    end

    test "works with get" do
      conn =
        :get
        |> conn("/status/my-service")
        |> Router.call(%{})

      assert conn.resp_body == "{\"status\":\":not_ready\"}"
    end

    test "works with post" do
      conn =
        :post
        |> conn("/status/my-service")
        |> Router.call(%{})

      assert conn.resp_body == "{\"status\":\":not_ready\"}"
    end
  end

  describe "definition" do
    setup do
      OctopusAgent.define(@definition)
      :ok
    end

    test "success case" do
      conn =
        :get
        |> conn("/definition/my-service")
        |> Router.call(%{})

      assert conn.resp_body == @definition
    end

    test "error case, undefined service" do
      conn =
        :get
        |> conn("/definition/undefined")
        |> Router.call(%{})

      assert conn.resp_body == "{\"error\":\":undefined\"}"
    end
  end

  describe "state" do
    setup do
      OctopusAgent.define(@definition)
      :ok
    end

    test "success case" do
      OctopusAgent.start("my-service")

      conn =
        :get
        |> conn("/state/my-service")
        |> Router.call(%{})

      assert conn.resp_body ==
               "{\"args\":{},\"configs\":{\"baz\":10,\"foo\":\"bar\"},\"state\":\"here\"}"
    end

    test "error case, not ready" do
      conn =
        :get
        |> conn("/state/my-service")
        |> Router.call(%{})

      assert conn.resp_body == "{\"error\":\":not_ready\"}"
    end

    test "error case, undefined service" do
      conn =
        :get
        |> conn("/state/undefined")
        |> Router.call(%{})

      assert conn.resp_body == "{\"error\":\":undefined\"}"
    end
  end

  describe "start" do
    setup do
      OctopusAgent.define(@definition)
      :ok
    end

    test "success" do
      conn =
        :post
        |> conn("/start/my-service")
        |> Router.call(%{})

      assert %{"ok" => %{"state" => "here"}} = Jason.decode!(conn.resp_body)
    end

    test "error" do
      conn =
        :post
        |> conn("/start/my-service", Jason.encode!(%{"fail" => "boom!"}))
        |> Router.call(%{})

      assert String.contains?(conn.resp_body, "boom!")
    end
  end

  describe "call" do
    setup do
      OctopusAgent.define(@definition)
      OctopusAgent.start("my-service")
      :ok
    end

    test "success" do
      conn =
        :post
        |> conn("/call/my-service/my_function", Jason.encode!(%{"in" => "in"}))
        |> Router.call(%{})

      assert conn.resp_body == "{\"ok\":{\"out\":\"inbaz\"}}"
    end

    test "error" do
      conn =
        :post
        |> conn("/call/my-service/my_function", Jason.encode!(%{"in" => "fail"}))
        |> Router.call(%{})

      assert String.contains?(conn.resp_body, "fail")
    end
  end

  describe "stop" do
    setup do
      OctopusAgent.define(@definition)
      OctopusAgent.start("my-service")
      :ok
    end

    test "success" do
      conn =
        :post
        |> conn("/stop/my-service")
        |> Router.call(%{})

      assert conn.resp_body == "{\"ok\":\"ok\"}"
    end

    test "error, when not started" do
      OctopusAgent.stop("my-service")

      conn =
        :post
        |> conn("/stop/my-service")
        |> Router.call(%{})

      assert conn.resp_body == "{\"error\":\":not_ready\"}"
    end
  end

  describe "restart" do
    setup do
      OctopusAgent.define(@definition)
      OctopusAgent.start("my-service")
      :ok
    end

    test "success" do
      conn =
        :post
        |> conn("/restart/my-service")
        |> Router.call(%{})

      assert %{"ok" => %{"state" => "here"}} = Jason.decode!(conn.resp_body)
    end

    test "error, when not started" do
      OctopusAgent.stop("my-service")

      conn =
        :post
        |> conn("/restart/my-service")
        |> Router.call(%{})

      assert conn.resp_body == "{\"error\":\":not_ready\"}"
    end
  end

  describe "delete" do
    setup do
      OctopusAgent.define(@definition)
      :ok
    end

    test "success" do
      conn =
        :post
        |> conn("/delete/my-service")
        |> Router.call(%{})

      assert conn.resp_body == "{\"ok\":\"ok\"}"
      assert OctopusAgent.status("my-service") == {:ok, "{\"status\":\":undefined\"}"}
    end

    test "error, when not defined" do
      OctopusAgent.delete("my-service")

      conn =
        :post
        |> conn("/delete/my-service")
        |> Router.call(%{})

      assert conn.resp_body == "{\"error\":\":undefined\"}"
    end
  end
end
