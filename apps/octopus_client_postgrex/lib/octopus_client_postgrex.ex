defmodule OctopusClientPostgrex do
  defmodule Error do
    defexception [:message]
  end

  @spec init(map(), map()) :: {:ok, map()} | no_return()
  def init(args, configs) do
    host = args["host"] || configs["host"]
    port = args["port"] || configs["port"]
    database = args["database"] || configs["database"]
    username = args["username"] || configs["username"]
    password = args["password"] || configs["password"]

    name =
      String.to_atom(args["process_name"] || configs["process_name"] || generate_process_name())

    spec =
      {Postgrex,
       host: host,
       port: port,
       database: database,
       username: username,
       password: password,
       name: name}

    pid =
      case DynamicSupervisor.start_child(__MODULE__.DynamicSupervisor, spec) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    state = %{
      pid: pid,
      name: name,
      host: host,
      port: port,
      database: database,
      username: username,
      password: password
    }

    {:ok, state}
  end

  @spec call(map(), map(), map()) :: {:ok, map()} | {:error, Error.t()}
  def call(args, configs, state) do
    statement = args["statement"] || configs["statement"]
    params = args["params"] || configs["params"] || []
    opts = opts_to_keyword_list(args["opts"] || configs["opts"] || %{})

    case Postgrex.query(state.name, statement, params, opts) do
      {:ok, %Postgrex.Result{columns: columns, num_rows: num_rows, rows: rows}} ->
        {:ok, %{"columns" => columns, "num_rows" => num_rows, "rows" => rows}}

      {:error, error} ->
        {:error, %Error{message: inspect(error)}}
    end
  end

  defp generate_process_name() do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    "#{__MODULE__}#{timestamp}"
  end

  defp opts_to_keyword_list(opts) do
    opts
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, String.to_atom(key), value)
    end)
    |> Enum.into([])
  end
end
