defmodule OctopusAgent.Router do
  use Plug.Router

  alias Api.Definition

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Hey! I'm Octopus Agent!")
  end

  get "/favicon.ico" do
    send_resp(conn, 200, "sorry, no icon")
  end

  post "/define" do
    {:ok, body, conn} = read_body(conn)
    map = Jason.decode!(body)

    case Octopus.define(map) do
      {:ok, name} ->
        send_resp(conn, 200, Jason.encode!(%{ok: name}))

      {:error, reason} ->
        send_resp(conn, 400, Jason.encode!(%{error: reason}))
    end
  end

  post "/init/:name" do
    {:ok, body, conn} = read_body(conn)
    map = Jason.decode!(body)

    case Octopus.init(conn.params["name"], map) do
      {:ok, state} ->
        send_resp(conn, 200, Jason.encode!(state))

      {:error, reason} ->
        send_resp(conn, 400, Jason.encode!(%{error: reason}))
    end
  end

  post "services/:name/:function" do
    {:ok, body, conn} = read_body(conn)
    map = Jason.decode!(body)

    case Octopus.call(conn.params["name"], conn.params["function"], map) do
      {:ok, result} ->
        send_resp(conn, 200, Jason.encode!(result))

      {:error, reason} ->
        send_resp(conn, 400, Jason.encode!(%{error: reason}))
    end
  end

  match _ do
    send_resp(conn, 404, "NOT FOUND")
  end
end
