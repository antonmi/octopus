defmodule OctopusTest do
  use ExUnit.Case, async: true
  alias Octopus.Test.Definitions

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

  describe "definition/1" do
    test "define and get definition" do
      {:ok, "my-service"} = Octopus.define(@definition)

      {:ok, definition} = Octopus.definition("my-service")
      assert definition == @definition
    end

    test "error when no such service" do
      {:error, :undefined} = Octopus.definition("my-service")
    end
  end

  describe "start/2" do
    test "when status is :undefined" do
      assert {:error, :undefined} = Octopus.start("my-service")
    end

    test "define and start" do
      {:ok, "my-service"} = Octopus.define(@definition)

      assert {:ok, state} = Octopus.start("my-service")
      assert state["name"] == Octopus.Services.MyService
      assert Process.alive?(state["pid"])

      assert {:error, :already_started} = Octopus.start("my-service")
    end

    test "when error during start" do
      {:ok, "my-service"} = Octopus.define(@definition)

      assert {:error, "%RuntimeError{message: \"boom!\"}"} =
               Octopus.start("my-service", %{"fail" => "boom!"})
    end
  end

  describe "state/1" do
    test "define, start, and get state" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, state} = Octopus.start("my-service")

      {:ok, ^state} = Octopus.state("my-service")
    end

    test "error when no such service" do
      {:error, :undefined} = Octopus.state("my-service")
    end
  end

  describe "services" do
    setup do
      {:ok, "my-service"} = Octopus.define(@definition)
      {:ok, "another-service"} = Octopus.define(Map.put(@definition, "name", "another-service"))

      on_exit(fn ->
        Octopus.delete("my-service")
        Octopus.delete("another-service")
      end)
    end

    test "list services" do
      services = Octopus.services()
      assert Enum.member?(services, "my-service")
      assert Enum.member?(services, "another-service")
    end
  end

  describe "call/3" do
    test "when status is :undefined" do
      assert {:error, :undefined} = Octopus.call("my-service", "my_function", %{"in" => "in"})
    end

    test "when status is :not_ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:error, :not_ready} = Octopus.call("my-service", "my_function", %{"in" => "in"})
    end

    test "when :ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, _state} = Octopus.start("my-service")

      assert {:ok, %{"out" => "inbaz"}} =
               Octopus.call("my-service", "my_function", %{"in" => "in"})
    end

    test "when fails" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, _state} = Octopus.start("my-service")

      assert {:error, %Octopus.CallError{message: "fail", step: :call}} =
               Octopus.call("my-service", "my_function", %{"in" => "fail"})
    end
  end

  describe "stop/2" do
    test "when status is :undefined" do
      assert {:error, :undefined} = Octopus.stop("my-service")
    end

    test "when status is :not_ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:error, :not_ready} = Octopus.stop("my-service")
    end

    test "when :ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, state} = Octopus.start("my-service")
      assert :ok = Octopus.stop("my-service")
      refute Process.alive?(state["pid"])
      assert Octopus.status("my-service") == :not_ready
    end
  end

  describe "restart/2" do
    test "when status is :undefined" do
      assert {:error, :undefined} = Octopus.restart("my-service")
    end

    test "when status is :not_ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:error, :not_ready} = Octopus.restart("my-service")
    end

    test "when :ready" do
      {:ok, "my-service"} = Octopus.define(@definition)
      assert {:ok, state} = Octopus.start("my-service")
      assert {:ok, new_state} = Octopus.restart("my-service")
      assert Process.alive?(new_state["pid"])
      refute Process.alive?(state["pid"])
      assert Octopus.status("my-service") == :ready
    end
  end

  describe "delete/2" do
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
      assert {:ok, state} = Octopus.start("my-service")
      assert Octopus.status("my-service") == :ready
      :ok = Octopus.delete("my-service")
      assert Octopus.status("my-service") == :undefined
      refute Process.alive?(state["pid"])
      refute Octopus.Utils.module_exist?(Octopus.Services.MyService.State)
      refute Octopus.Utils.module_exist?(Octopus.Services.MyService)
    end
  end
end
