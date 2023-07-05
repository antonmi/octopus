defmodule OctopusAgent.RequestsWithClientErrorTest do
  use ExUnit.Case
  use Plug.Test

  alias OctopusAgent.Router
  alias OctopusAgent.Test.Definitions

  defmodule Client do
    def start(args, configs, _service_name) do
      {:ok, %{"state" => "here", "args" => args, "configs" => configs}}
    end

    def call(%{"foo" => foo}, _configs, _state) do
      case foo do
        "fail" ->
          raise "fail"

        "error" ->
          {:error, %{"extra" => "ooops"}}

        "error_struct" ->
          {:error, %RuntimeError{message: "ooops"}}

        "error_string" ->
          {:error, "ooops"}

        foo ->
          {:ok, %{"bar" => foo <> "baz"}}
      end
    end

    def stop(_args, _configs, _state) do
      :ok
    end
  end

  @definition Definitions.read_from_octopus("example_for_errors.json")
              |> Jason.decode!()
              |> put_in(["name"], "my-service")
              |> put_in(["client", "module"], "OctopusAgent.RequestsWithClientErrorTest.Client")
              |> Jason.encode!()

  setup do
    on_exit(fn ->
      OctopusAgent.delete("my-service")
    end)
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

    test "exception" do
      conn =
        :post
        |> conn("/call/my-service/my_function", Jason.encode!(%{"in" => "fail"}))
        |> Router.call(%{})

      assert String.contains?(conn.resp_body, "fail")
      assert String.contains?(conn.resp_body, "%Octopus.CallError")
    end

    test "error with map" do
      conn =
        :post
        |> conn("/call/my-service/my_function", Jason.encode!(%{"in" => "error"}))
        |> Router.call(%{})

      assert String.contains?(conn.resp_body, "{\"ok\":{\"error\":{\"extra\":\"ooops\"}")
    end

    test "error with struct" do
      conn =
        :post
        |> conn("/call/my-service/my_function", Jason.encode!(%{"in" => "error_struct"}))
        |> Router.call(%{})

      assert String.contains?(conn.resp_body, "{\"ok\":{\"error\":\"%RuntimeError")
    end

    test "error with error_string" do
      conn =
        :post
        |> conn("/call/my-service/my_function", Jason.encode!(%{"in" => "error_string"}))
        |> Router.call(%{})

      assert String.contains?(conn.resp_body, "{\"ok\":{\"error\":\"ooops\"")
    end
  end
end
