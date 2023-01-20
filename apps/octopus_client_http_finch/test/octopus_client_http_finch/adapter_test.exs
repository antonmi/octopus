defmodule OctopusClientHttpFinch.AdapterTest do
  use ExUnit.Case, async: true

  alias OctopusClientHttpFinch.Adapter

  @base_url "http://localhost"
  @headers %{"Content-Type" => "application/json"}

  describe "call/2 with GET" do
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

      {:ok, state} = OctopusClientHttpFinch.start(args)
      %{bypass: bypass, state: state}
    end

    test "call the client", %{bypass: bypass, state: state} do
      Bypass.expect(bypass, "GET", "/path", fn conn ->
        assert Enum.member?(conn.req_headers, {"content-type", "application/json"})
        assert conn.params == %{"a" => "1", "b" => "c"}
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"hello" => "world"}))
      end)

      {:ok, result} = Adapter.call(@args_for_get, %{}, state)

      decoded_body = Jason.decode!(result["body"])
      assert decoded_body == %{"hello" => "world"}
    end
  end

  describe "call/2 with POST" do
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

      {:ok, state} = OctopusClientHttpFinch.start(args)
      %{bypass: bypass, state: state}
    end

    test "call the client", %{bypass: bypass, state: state} do
      Bypass.expect(bypass, "POST", "/path", fn conn ->
        assert Enum.member?(conn.req_headers, {"content-length", "17"})
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == "{\"hello\":\"world\"}"
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"ok" => "ok"}))
      end)

      {:ok, result} = Adapter.call(@args_for_post, %{}, state)

      decoded_body = Jason.decode!(result["body"])
      assert decoded_body == %{"ok" => "ok"}

      {:ok, result} = Adapter.call(@args_for_post, %{"parse_json_body" => true}, state)

      assert result["body"] == %{"ok" => "ok"}
    end
  end
end
