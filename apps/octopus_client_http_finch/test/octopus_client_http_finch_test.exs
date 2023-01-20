defmodule OctopusClientHttpFinchTest do
  use ExUnit.Case

  alias OctopusClientHttpFinch
  alias OctopusClientHttpFinch.{Request, Response, State}

  @base_url "http://localhost"
  @headers %{"Content-Type" => "application/json"}

  describe "start/1" do
    setup do
      args = %{"base_url" => @base_url, "headers" => @headers}
      configs = %{"pool_size" => 10}
      {:ok, %State{} = state} = OctopusClientHttpFinch.start(args, configs)
      %{state: state}
    end

    test "checks a state", %{state: state} do
      assert Process.alive?(state.pid)
      assert state.base_url == @base_url
      assert state.headers == %{"Content-Type" => "application/json"}
      assert state.pool_size == 10
      assert state.pid != nil
      assert state.name
    end

    test "start another client", %{state: state} do
      args = %{"base_url" => @base_url, "headers" => @headers}
      configs = %{"process_name" => "another_client"}
      {:ok, %State{} = new_state} = OctopusClientHttpFinch.start(args, configs)
      assert Process.alive?(Process.whereis(state.name))
      assert Process.alive?(Process.whereis(new_state.name))
    end
  end

  describe "call" do
    setup do
      bypass = Bypass.open()

      args = %{
        "base_url" => "#{@base_url}:#{bypass.port}",
        "headers" => @headers,
        "pool_size" => 10
      }

      {:ok, state} = OctopusClientHttpFinch.start(args, %{"process_name" => "test"})
      %{state: state, bypass: bypass}
    end

    test "call with GET", %{bypass: bypass, state: state} do
      Bypass.expect(bypass, "GET", "/path", fn conn ->
        assert Enum.member?(conn.req_headers, {"custom", "header"})
        assert conn.params == %{"a" => "1", "b" => "b"}
        Plug.Conn.resp(conn, 200, "OK")
      end)

      args = %Request{
        method: :get,
        path: "/path",
        params: %{a: 1, b: "b"},
        body: "",
        headers: %{"custom" => "header"}
      }

      {:ok, %Response{} = response} = OctopusClientHttpFinch.call(args, state)
      assert response.status == 200
      assert response.body == "OK"
      assert Enum.member?(response.headers, {"content-length", "2"})
    end

    test "call with POST", %{bypass: bypass, state: state} do
      Bypass.expect(bypass, "POST", "/path", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == "body"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      args = %Request{method: :post, path: "/path", params: %{}, body: "body"}
      {:ok, %Response{} = response} = OctopusClientHttpFinch.call(args, state)
      assert response.status == 200
      assert response.body == "OK"
      assert Enum.member?(response.headers, {"content-length", "2"})
    end

    test "500 error", %{state: state} do
      args = %Request{method: :get, path: "%%%", params: %{}, body: ""}
      assert {:error, %Mint.HTTPError{}} = OctopusClientHttpFinch.call(args, state)
    end
  end
end
