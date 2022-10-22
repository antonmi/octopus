defmodule Octopus.Executors.JsonApi do
  def call(method, url, params) when method in [:get, :post] do
    url =
      url
      |> URI.parse()
      |> Map.put(:query, URI.encode_query(params))

    Finch.build(method, url)
    |> Finch.request(Octopus.Finch)
    |> case do
      {:ok, %Finch.Response{body: body}} ->
        Jason.decode(body)

      {:error, error} ->
        {:error, error}
    end
  end
end
