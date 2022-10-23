defmodule Api.Router do
  use Plug.Router

  alias Api.Definition
  alias Api.Eval

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "It's ok")
  end

  get "/favicon.ico" do
    send_resp(conn, 200, "sorry")
  end

  get "/api/test" do
    send_resp(conn, 200, "It's ok")
  end

  post "/define" do
    case Definition.define(conn.params) do
      {:ok, code} ->
        send_resp(conn, 200, Jason.encode!(%{code: code}))
    end
  end

  post "services/:name/:function" do
    case Eval.eval(conn.params["name"], conn.params["function"], conn.body_params) do
      {:ok, result} ->
        send_resp(conn, 200, result)
    end
  end

  match _ do
    send_resp(conn, 404, "NOT FOUND")
  end
end
