defmodule OctopusClientHttpFinchTest do
  use ExUnit.Case

  @base_url "http://localhost"
  @headers %{"Content-Type" => "application/json"}

  describe "init/1" do
    setup do
      args = %{"base_url" => @base_url, "headers" => @headers}
      configs = %{"pool_size" => 10}
      {:ok, state} = OctopusClientHttpFinch.init(args, configs)
      %{state: state}
    end

    test "checks the state", %{state: state} do
      assert Process.alive?(Process.whereis(state.name))
      assert state.base_url == @base_url
      assert state.headers == %{"Content-Type" => "application/json"}
      assert state.pool_size == 10
      assert state.pid != nil
    end

    test "init another client", %{state: state} do
      args = %{"base_url" => @base_url, "headers" => @headers}
      configs = %{"process_name" => "another_client"}
      {:ok, new_state} = OctopusClientHttpFinch.init(args, configs)
      assert Process.alive?(Process.whereis(state.name))
      assert Process.alive?(Process.whereis(new_state.name))
    end
  end

  describe "call/3 with GET" do
    @args_for_get %{
      "method" => "GET",
      "path" => "/path",
      "params" => %{"a" => 1, "b" => "c"},
      "headers" => %{"Content-Type" => "application/json"}
    }

    setup do
      bypass = Bypass.open()

      args = %{
        "base_url" => "#{@base_url}:#{bypass.port}",
        "headers" => @headers,
        "pool_size" => 10
      }

      {:ok, state} = OctopusClientHttpFinch.init(args)
      %{bypass: bypass, state: state}
    end

    test "call the client", %{bypass: bypass, state: state} do
      Bypass.expect(bypass, "GET", "/path", fn conn ->
        assert Enum.member?(conn.req_headers, {"content-type", "application/json"})
        assert conn.params == %{"a" => "1", "b" => "c"}
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"hello" => "world"}))
      end)

      {:ok, result} = OctopusClientHttpFinch.call(@args_for_get, %{}, state)

      decoded_body = Jason.decode!(result["body"])
      assert decoded_body == %{"hello" => "world"}
    end
  end

  describe "call/3 with POST" do
    @args_for_post %{
      "method" => "POST",
      "path" => "/path",
      "body" => "{\"hello\":\"world\"}",
      "headers" => %{"Content-Type" => "application/json"}
    }

    setup do
      bypass = Bypass.open()

      args = %{
        "base_url" => "#{@base_url}:#{bypass.port}",
        "headers" => @headers,
        "pool_size" => 10
      }

      {:ok, state} = OctopusClientHttpFinch.init(args)
      %{bypass: bypass, state: state}
    end

    test "call the client", %{bypass: bypass, state: state} do
      Bypass.expect(bypass, "POST", "/path", fn conn ->
        assert Enum.member?(conn.req_headers, {"content-length", "17"})
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == "{\"hello\":\"world\"}"
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"ok" => "ok"}))
      end)

      {:ok, result} = OctopusClientHttpFinch.call(@args_for_post, %{}, state)

      decoded_body = Jason.decode!(result["body"])
      assert decoded_body == %{"ok" => "ok"}

      {:ok, result} =
        OctopusClientHttpFinch.call(@args_for_post, %{"parse_json_body" => true}, state)

      assert result["body"] == %{"ok" => "ok"}
    end
  end
end
