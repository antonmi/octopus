defmodule Octopus.Rpc.JsonApi.Call do
  def call(params, config) do
    url = build_url(config["url"], params)
    method = parse_method(config["method"])

    Finch.build(method, url)
    |> Finch.request(Octopus.Finch)
    |> case do
      {:ok, %Finch.Response{body: body}} ->
        {:ok, body}

      {:error, error} ->
        {:error, error}
    end
  end

  defp build_url(url, params) do
    url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(params))
  end

  defp parse_method(method) do
    case method do
      "GET" -> :get
      "POST" -> :post
    end
  end
end
