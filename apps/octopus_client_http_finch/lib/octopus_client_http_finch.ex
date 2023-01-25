defmodule OctopusClientHttpFinch do
  @moduledoc false

  @default_pool_size 10

  @spec start(map(), map()) :: {:ok, map()}
  def start(args, configs \\ %{}) do
    base_url = args["base_url"] || configs["base_url"]
    headers = Map.merge(configs["headers"] || %{}, args["headers"] || %{})
    pool_size = args["pool_size"] || configs["pool_size"] || @default_pool_size

    name =
      String.to_atom(args["process_name"] || configs["process_name"] || generate_process_name())

    spec = {Finch, name: name, pools: %{base_url => [size: pool_size]}}

    pid =
      case DynamicSupervisor.start_child(__MODULE__.DynamicSupervisor, spec) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    state = %{
      pid: pid,
      name: name,
      base_url: base_url,
      headers: headers,
      pool_size: pool_size
    }

    {:ok, state}
  end

  @spec call(map(), map(), term()) :: map()
  def call(args, configs, state) do
    method = method_to_atom(args["method"])
    headers = args["headers"] || %{}

    cond do
      method in [:get, :head, :delete, :options] ->
        %{
          method: method,
          path: args["path"] || "/",
          params: args["params"] || %{},
          headers: headers,
          body: nil
        }
        |> do_call(configs, state)

      method in [:post, :put, :patch] ->
        headers = Map.put(headers, "Content-Length", "#{byte_size(args["body"])}")

        %{
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
    case finch_call(request, state) do
      {:ok, %{body: body} = response} ->
        headers = response.headers |> Enum.into(%{})
        body = if configs["parse_json_body"], do: Jason.decode!(body), else: body
        status = response.status
        {:ok, %{"status" => status, "headers" => headers, "body" => body}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp finch_call(request, state) do
    url = build_url(state.base_url, request.path, request.params)
    headers = headers_to_list(Map.merge(state.headers, request.headers))

    request.method
    |> Finch.build(url, headers, request.body)
    |> Finch.request(state.name)
    |> case do
      {:ok, %Finch.Response{status: status, body: body, headers: headers}} ->
        {:ok, %{status: status, body: body, headers: headers}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp generate_process_name() do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    "#{__MODULE__}#{timestamp}"
  end

  defp build_url(url, path, params) do
    url
    |> URI.parse()
    |> Map.put(:path, prefix_with_slash_if_needed(path))
    |> Map.put(:query, URI.encode_query(params))
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

  defp headers_to_list(headers) do
    Enum.reduce(headers, [], fn {key, value}, acc -> [{key, value} | acc] end)
  end

  defp prefix_with_slash_if_needed("/" <> path), do: "/" <> path
  defp prefix_with_slash_if_needed(path), do: "/" <> path
end
