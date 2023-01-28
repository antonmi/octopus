defmodule OctopusAgentTest do
  use ExUnit.Case, async: true
  alias OctopusAgent.Test.Definitions

  defmodule Client do
    def start(args, _configs, service_module) do
      if args["fail"] do
        raise args["fail"]
      end

      case Agent.start_link(fn -> %{} end, name: service_module) do
        {:ok, pid} ->
          {:ok, %{"pid" => pid, "name" => service_module}}

        {:error, {:already_started, _pid}} ->
          {:error, :already_started}
      end
    end

    def call(%{"foo" => foo}, _configs, _state) do
      if foo == "fail" do
        raise "fail"
      end

      {:ok, %{"bar" => foo <> "baz"}}
    end

    def stop(_args, _configs, state) do
      if Process.alive?(state["pid"]) do
        Agent.stop(state["pid"])
      end

      :ok
    end
  end

  @definition Definitions.read_from_octopus("example.json")
              |> Jason.decode!()
              |> put_in(["name"], "my-service")
              |> put_in(["client", "module"], "OctopusAgentTest.Client")
              |> Jason.encode!()

  setup do
    on_exit(fn ->
      OctopusAgent.delete("my-service")
    end)
  end

  describe "define/1" do
    test "define and check statuses" do
      assert {:ok, "{\"status\":\":undefined\"}"} = OctopusAgent.status("my-service")
      assert {:ok, "{\"ok\":\"my-service\"}"} = OctopusAgent.define(@definition)
      assert {:ok, "{\"status\":\":not_ready\"}"} = OctopusAgent.status("my-service")
    end

    test "error in definition" do
      {:error, result} =
        @definition
        |> Jason.decode!()
        |> put_in(["name"], nil)
        |> Jason.encode!()
        |> OctopusAgent.define()

      assert String.contains?(result, "Missing service name!")
    end
  end

  describe "start" do
    test "when status is :undefined" do
      assert {:error, "{\"error\":\":undefined\"}"} = OctopusAgent.start("my-service")
    end

    test "define and start" do
      {:ok, "{\"ok\":\"my-service\"}"} = OctopusAgent.define(@definition)

      {:ok, result} = OctopusAgent.start("my-service", "")
      assert get_in(Jason.decode!(result), ["ok", "pid"])
      assert get_in(Jason.decode!(result), ["ok", "name"]) == "Elixir.Octopus.Services.MyService"
      assert {:error, "{\"error\":\":already_started\"}"} = OctopusAgent.start("my-service")
    end

    test "when error during start" do
      {:ok, "{\"ok\":\"my-service\"}"} = OctopusAgent.define(@definition)

      {:error, result} = OctopusAgent.start("my-service", Jason.encode!(%{"fail" => "boom!"}))
      assert String.contains?(result, "boom!")
    end
  end

  describe "call" do
    test "when success" do
      OctopusAgent.define(@definition)
      OctopusAgent.start("my-service", "")

      {:ok, result} =
        OctopusAgent.call("my-service", "my_function", Jason.encode!(%{"in" => "in"}))

      assert result == "{\"ok\":{\"out\":\"inbaz\"}}"
    end

    test "when fails" do
      OctopusAgent.define(@definition)
      OctopusAgent.start("my-service", "")

      {:error, result} =
        OctopusAgent.call("my-service", "my_function", Jason.encode!(%{"in" => "fail"}))

      assert String.contains?(result, "fail")
    end
  end

  describe "stop" do
    test "when status is :not_ready" do
      OctopusAgent.define(@definition)
      assert {:error, "{\"error\":\":not_ready\"}"} = OctopusAgent.stop("my-service")
    end

    test "when :ready" do
      OctopusAgent.define(@definition)
      OctopusAgent.start("my-service")
      assert {:ok, "{\"ok\":\"ok\"}"} = OctopusAgent.stop("my-service")
    end
  end

  describe "restart" do
    test "when :ready" do
      OctopusAgent.define(@definition)
      OctopusAgent.start("my-service")
      {:ok, result} = OctopusAgent.restart("my-service")
      assert get_in(Jason.decode!(result), ["ok", "pid"])
      assert get_in(Jason.decode!(result), ["ok", "name"]) == "Elixir.Octopus.Services.MyService"
    end
  end

  describe "delete" do
    test "when :ready" do
      OctopusAgent.define(@definition)
      OctopusAgent.start("my-service")
      assert {:ok, "{\"ok\":\"ok\"}"} = OctopusAgent.delete("my-service")
    end
  end
end
