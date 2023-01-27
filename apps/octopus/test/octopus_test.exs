defmodule OctopusTest do
  use ExUnit.Case, async: true
  alias Octopus.Test.Definitions

  defmodule Client do
    def init(args, _configs, service_module) do
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

  @definition Definitions.read_and_decode("example.json")
              |> put_in(["name"], "my-service")
              |> put_in(["client", "module"], "OctopusTest.Client")

  setup do
    on_exit(fn ->
      Octopus.delete("my-service")
    end)
  end

  describe "define/1" do
    test "define and check statuses" do
      assert Octopus.status("my-service") == :undefined

      {:ok, "my-service"} = Octopus.define(@definition)
      assert Octopus.status("my-service") == :not_ready
    end

    test "error in definition" do
      assert {:error, %Octopus.Error{message: "Missing service name!"}} =
               @definition
               |> put_in(["name"], nil)
               |> Octopus.define()
    end
  end

  describe "init" do
    test "when status is :undefined" do
      assert {:error, :undefined} = Octopus.init("my-service")
    end

    test "define and start" do
      {:ok, "my-service"} = Octopus.define(@definition)

      assert {:ok, state} = Octopus.init("my-service")
      assert state["name"] == Octopus.Services.MyService
      assert Process.alive?(state["pid"])

      assert {:error, :already_started} = Octopus.init("my-service")
    end

    test "when error during init" do
      {:ok, "my-service"} = Octopus.define(@definition)

      assert {:error, "%RuntimeError{message: \"boom!\"}"} =
               Octopus.init("my-service", %{"fail" => "boom!"})
    end
  end

  describe "call" do
    test "when status is :undefined" do
      assert {:error, :undefined} = Octopus.call("my-service", "my_function", %{"in" => "in"})
    end

    test "when status is :not_ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:error, :not_ready} = Octopus.call("my-service", "my_function", %{"in" => "in"})
    end

    test "when :ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, _state} = Octopus.init("my-service")

      assert {:ok, %{"out" => "inbaz"}} =
               Octopus.call("my-service", "my_function", %{"in" => "in"})
    end

    test "when fails" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, _state} = Octopus.init("my-service")

      assert {:error, %RuntimeError{__exception__: true, message: "fail"}} =
               Octopus.call("my-service", "my_function", %{"in" => "fail"})
    end
  end

  describe "stop" do
    test "when status is :undefined" do
      assert {:error, :undefined} = Octopus.stop("my-service")
    end

    test "when status is :not_ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:error, :not_ready} = Octopus.stop("my-service")
    end

    test "when :ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, state} = Octopus.init("my-service")
      assert :ok = Octopus.stop("my-service")
      refute Process.alive?(state["pid"])
      assert Octopus.status("my-service") == :not_ready
    end
  end

  describe "restart" do
    test "when status is :undefined" do
      assert {:error, :undefined} = Octopus.restart("my-service")
    end

    test "when status is :not_ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:error, :not_ready} = Octopus.restart("my-service")
    end

    test "when :ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, state} = Octopus.init("my-service")
      assert {:ok, new_state} = Octopus.restart("my-service")
      assert Process.alive?(new_state["pid"])
      refute Process.alive?(state["pid"])
      assert Octopus.status("my-service") == :ready
    end
  end

  describe "delete" do
    test "when status is :undefined" do
      assert {:error, :undefined} = Octopus.delete("my-service")
    end

    test "when status is :not_ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert Octopus.status("my-service") == :not_ready
      :ok = Octopus.delete("my-service")
      assert Octopus.status("my-service") == :undefined
      refute Octopus.Utils.module_exist?(Octopus.Services.MyService.State)
      refute Octopus.Utils.module_exist?(Octopus.Services.MyService)
    end

    test "when :ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, state} = Octopus.init("my-service")
      assert Octopus.status("my-service") == :ready
      :ok = Octopus.delete("my-service")
      assert Octopus.status("my-service") == :undefined
      refute Process.alive?(state["pid"])
      refute Octopus.Utils.module_exist?(Octopus.Services.MyService.State)
      refute Octopus.Utils.module_exist?(Octopus.Services.MyService)
    end
  end
end
