defmodule Octopus.Interface.JsonApi.Call do
  alias Octopus.Utils

  def call(params, %{"url" => url, "path" => path, "method" => method}) when method == "GET" do
    url = build_url(url, path, params)
    method = parse_method(method)

    do_request(Finch.build(method, url))
  end

  def call(data, %{"url" => url, "path" => path, "method" => method} = configs)
      when method == "POST" do
    url = build_url(url, path, %{})
    method = parse_method(method)
    headers = [{"Content-Length", "#{byte_size(data)}"} | prepare_headers(configs["headers"])]

    do_request(Finch.build(method, url, headers, data))
  end

  defp do_request(finch_request) do
    finch_request
    |> Finch.request(Octopus.Finch)
    |> case do
      {:ok, %Finch.Response{body: body}} ->
        {:ok, body}

      {:error, error} ->
        {:error, error}
    end
  end

  defp build_url(url, path, params) do
    path = Utils.eval_template(path, params, false)

    url
    |> URI.parse()
    |> Map.put(:path, path)
    |> Map.put(:query, URI.encode_query(params))
  end

  defp parse_method(method) do
    case method do
      "GET" -> :get
      "POST" -> :post
    end
  end

  defp prepare_headers(nil), do: []

  defp prepare_headers(config_headers) do
    config_headers
    |> Enum.reduce([], fn {key, value}, acc ->
      [{key, value} | acc]
    end)
  end
end
