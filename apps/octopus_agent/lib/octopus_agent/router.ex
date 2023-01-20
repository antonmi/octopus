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

  get "/api/test" do
    send_resp(conn, 200, "Octopus Agent is ok")
  end

  post "/define" do
    {:ok, body, conn} = read_body(conn)
    map = Jason.decode!(body)
    case Octopus.define(map) do
      {:ok, code} ->
        send_resp(conn, 200, Jason.encode!(%{code: code}))
    end
  end

#  post "services/:name/:function" do
#    case Octopus.Service.call(conn.params["name"], conn.params["function"], conn.body_params) do
#      {:ok, result} ->
#        send_resp(conn, 200, maybe_encode(result))
#
#      {:error, error} ->
#        send_resp(conn, 500, inspect(error))
#    end
#  end
#
#  defp maybe_encode(result) when is_map(result), do: Jason.encode!(result)
#  defp maybe_encode(result) when is_binary(result), do: result
#  defp maybe_encode(result) when is_number(result), do: "#{result}"

  match _ do
    send_resp(conn, 404, "NOT FOUND")
  end
end
