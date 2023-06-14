defmodule Octopus.CallErrorsTest do
  use ExUnit.Case, async: true
  alias Octopus.CallError
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
      case foo do
        "fail" ->
          raise "fail"

        "error" ->
          {:error, %{"message" => "ooops", "data" => "data"}}

        "error_struct" ->
          {:error, %RuntimeError{message: "ooops"}}

        "error_string" ->
          {:error, "ooops"}

        foo ->
          {:ok, %{"bar" => foo <> "baz"}}
      end
    end

    def stop(_args, _configs, state) do
      if Process.alive?(state["pid"]) do
        Agent.stop(state["pid"])
      end

      :ok
    end
  end

  @definition Definitions.read_and_decode("example_for_errors.json")
              |> put_in(["name"], "buggy-service")
              |> put_in(["client", "module"], "Octopus.CallErrorsTest.Client")

  def define_and_start(definition) do
    {:ok, "buggy-service"} = Octopus.define(definition)
    {:ok, _state} = Octopus.start("buggy-service")
  end

  setup do
    on_exit(fn ->
      Octopus.delete("buggy-service")
    end)
  end

  test "check if the service works" do
    {:ok, "buggy-service"} = Octopus.define(@definition)
    {:ok, _state} = Octopus.start("buggy-service")

    assert {:ok, %{"out" => "inbaz"}} =
             Octopus.call("buggy-service", "my_function", %{"in" => "in"})
  end

  describe "error in input " do
    test "wrong type" do
      define_and_start(@definition)
      {:error, %CallError{} = error} = Octopus.call("buggy-service", "my_function", %{"in" => 1})
      assert error.type == :input
      assert error.message == "#/in:Type mismatch. Expected String but got Integer."
      refute error.stacktrace
    end

    test "wrong type specification" do
      @definition
      |> put_in(["interface", "my_function", "input", "in", "type"], "unknown")
      |> define_and_start()

      {:error, %CallError{} = error} = Octopus.call("buggy-service", "my_function", %{"in" => 1})

      assert error.type == :input
      assert error.message =~ "schema did not pass validation against"
      assert is_list(error.stacktrace)
    end
  end

  describe "error in output " do
    test "no type in output" do
      @definition
      |> put_in(["interface", "my_function", "transform"], %{
        "out" => "String.length(args['bar'])"
      })
      |> define_and_start()

      {:error, %CallError{} = error} =
        Octopus.call("buggy-service", "my_function", %{"in" => "in"})

      assert error.type == :output
      assert error.message == "#/out:Type mismatch. Expected String but got Integer."
      refute error.stacktrace
    end

    test "wrong type specification" do
      @definition
      |> put_in(["interface", "my_function", "output", "out", "type"], "unknown")
      |> define_and_start()

      {:error, %CallError{} = error} =
        Octopus.call("buggy-service", "my_function", %{"in" => "in"})

      assert error.type == :output
      assert error.message =~ "schema did not pass validation against"
      assert is_list(error.stacktrace)
    end
  end

  describe "error in prepare" do
    test "error in Elixir code" do
      @definition
      |> put_in(["interface", "my_function", "prepare", "foo"], "args.in")
      |> define_and_start()

      {:error, %CallError{} = error} =
        Octopus.call("buggy-service", "my_function", %{"in" => "in"})

      assert error.type == :prepare
      assert error.message =~ "Non local call"
      assert is_list(error.stacktrace)
    end

    test "when error in definition" do
      @definition
      |> put_in(["interface", "my_function", "prepare"], "not a map")
      |> define_and_start()

      {:error, %CallError{} = error} =
        Octopus.call("buggy-service", "my_function", %{"in" => "in"})

      assert error.type == :prepare
      assert error.message =~ "protocol Enumerable not implemented"
      assert is_list(error.stacktrace)
    end
  end

  describe "error in transform" do
    test "error in Elixir code" do
      @definition
      |> put_in(["interface", "my_function", "transform", "out"], "args.in")
      |> define_and_start()

      {:error, %CallError{} = error} =
        Octopus.call("buggy-service", "my_function", %{"in" => "in"})

      assert error.type == :transform
      assert error.message =~ "Non local call"
      assert is_list(error.stacktrace)
    end

    test "when error in definition" do
      @definition
      |> put_in(["interface", "my_function", "transform"], "not a map")
      |> define_and_start()

      {:error, %CallError{} = error} =
        Octopus.call("buggy-service", "my_function", %{"in" => "in"})

      assert error.type == :transform
      assert error.message =~ "protocol Enumerable not implemented"
      assert is_list(error.stacktrace)
    end
  end

  describe "error in call" do
    test "exception inside call" do
      define_and_start(@definition)

      {:error, %CallError{} = error} =
        Octopus.call("buggy-service", "my_function", %{"in" => "fail"})

      assert error.type == :call
      assert error.message == "fail"
      assert is_list(error.stacktrace)
    end
  end

  describe "handling a error with client_error" do
    test "error call" do
      define_and_start(@definition)

      {:ok, result} = Octopus.call("buggy-service", "my_function", %{"in" => "error"})
      assert result == %{"data" => "data", "error" => true, "message" => "ooops"}
    end

    test "error call when there is no client_error" do
      @definition
      |> put_in(["interface", "my_function", "client_error"], nil)
      |> define_and_start()

      {:error, %CallError{} = error} =
        Octopus.call("buggy-service", "my_function", %{"in" => "error"})

      assert error.type == :call
      assert error.message == "%{\"data\" => \"data\", \"message\" => \"ooops\"}"
    end

    test "error_struct call" do
      define_and_start(@definition)

      {:ok, result} = Octopus.call("buggy-service", "my_function", %{"in" => "error_struct"})
      assert result == %{"data" => nil, "error" => true, "message" => "ooops"}
    end

    test "error_string call" do
      define_and_start(@definition)

      {:ok, result} = Octopus.call("buggy-service", "my_function", %{"in" => "error_string"})
      assert result == %{"data" => nil, "error" => true, "message" => "ooops"}
    end
  end
end
