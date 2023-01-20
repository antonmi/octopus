defmodule OctopusClientHttpFinch.Adapter do
  alias OctopusClientHttpFinch.{Request, Response}

  @spec call(map(), map(), term()) :: map()
  def call(args, configs, state) do
    method = method_to_atom(args["method"])
    headers = args["headers"] || %{}

    case method do
      :get ->
        %Request{
          method: method,
          path: args["path"] || "/",
          params: args["params"] || %{},
          headers: headers
        }
        |> do_call(configs, state)

      :post ->
        headers = Map.put(headers, "Content-Length", "#{byte_size(args["body"])}")

        %Request{
          method: method,
          path: args["path"] || "/",
          params: args["params"] || %{},
          body: args["body"] || "",
          headers: headers
        }
        |> do_call(configs, state)
    end
  end

  defp do_call(request, configs, state) do
    case OctopusClientHttpFinch.call(request, state) do
      {:ok, %Response{body: body} = response} ->
        headers = response.headers |> Enum.into(%{})
        body = if configs["parse_json_body"], do: Jason.decode!(body), else: body
        status = response.status
        {:ok, %{"status" => status, "headers" => headers, "body" => body}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp method_to_atom(method) when is_atom(method) do
    method
    |> Atom.to_string()
    |> String.replace("Elixir.", "")
    |> method_to_atom()
  end

  defp method_to_atom(method) when is_binary(method) do
    method
    |> String.downcase()
    |> String.to_atom()
  end
end
