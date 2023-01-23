defmodule OctopusClientHttpFinch do
  @moduledoc false

  defmodule State do
    @moduledoc false
    defstruct base_url: nil, headers: %{}, pool_size: nil, pid: nil, name: nil

    @type t :: %__MODULE__{
            base_url: String.t(),
            headers: map(),
            pool_size: integer(),
            pid: pid(),
            name: atom()
          }
  end

  defmodule Request do
    @moduledoc false
    defstruct method: :get, path: "/", params: %{}, body: nil, headers: %{}

    @type t :: %__MODULE__{
            method: atom(),
            path: String.t(),
            params: map(),
            body: String.t(),
            headers: map()
          }
  end

  defmodule Response do
    @moduledoc false
    defstruct status: nil, body: nil, headers: []

    @type t :: %__MODULE__{
            status: integer(),
            body: String.t(),
            headers: map()
          }
  end

  @default_pool_size 10

  def start(args, configs \\ %{}) do
    base_url = args["base_url"] || configs["base_url"]
    headers = args["headers"] || configs["headers"] || %{}
    pool_size = args["pool_size"] || configs["pool_size"] || @default_pool_size
    name = String.to_atom(configs["process_name"] || generate_process_name())

    spec = {Finch, name: name, pools: %{base_url => [size: pool_size]}}

    pid =
      case DynamicSupervisor.start_child(__MODULE__.DynamicSupervisor, spec) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    state = %State{
      pid: pid,
      name: name,
      base_url: base_url,
      headers: headers,
      pool_size: pool_size
    }

    {:ok, state}
  end

  @spec call(Request.t(), State.t()) :: {:ok, Response.t()} | {:error, Error.t()}
  def call(%Request{} = request, %State{} = state) do
    url = build_url(state.base_url, request.path, request.params)
    headers = headers_to_list(Map.merge(state.headers, request.headers))

    request.method
    |> Finch.build(url, headers, request.body)
    |> Finch.request(state.name)
    |> case do
      {:ok, %Finch.Response{status: status, body: body, headers: headers}} ->
        {:ok, %Response{status: status, body: body, headers: headers}}

      {:error, error} ->
        {:error, error}
    end
  end

  def generate_process_name() do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    "#{__MODULE__}#{timestamp}"
  end

  defp build_url(url, path, params) do
    url
    |> URI.parse()
    |> Map.put(:path, prefix_with_slash_if_needed(path))
    |> Map.put(:query, URI.encode_query(params))
  end

  defp headers_to_list(headers) do
    Enum.reduce(headers, [], fn {key, value}, acc -> [{key, value} | acc] end)
  end

  defp prefix_with_slash_if_needed("/" <> path), do: "/" <> path
  defp prefix_with_slash_if_needed(path), do: "/" <> path
end
