defmodule OctopusClientPostgrex do
  defmodule Error do
    defexception [:message]
  end

  @spec start(map(), map(), atom()) :: {:ok, map()} | {:error, :already_started}
  def start(args, configs, service_module) do
    host = args["host"] || configs["host"]
    port = args["port"] || configs["port"]
    database = args["database"] || configs["database"]
    username = args["username"] || configs["username"]
    password = args["password"] || configs["password"]

    process_name = args["process_name"] || configs["process_name"]

    name =
      case process_name do
        nil -> service_module
        specific_process_name -> String.to_atom(specific_process_name)
      end

    spec =
      {Postgrex,
       host: host,
       port: port,
       database: database,
       username: username,
       password: password,
       name: name}

    case DynamicSupervisor.start_child(__MODULE__.DynamicSupervisor, spec) do
      {:ok, pid} ->
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

      {:error, {:already_started, _pid}} ->
        {:error, :already_started}
    end
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

  @spec stop(map(), map(), any()) :: :ok | {:error, :not_found}
  def stop(_args, _configs, state) do
    DynamicSupervisor.terminate_child(__MODULE__.DynamicSupervisor, state.pid)
  end

  defp opts_to_keyword_list(opts) do
    opts
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, String.to_atom(key), value)
    end)
    |> Enum.into([])
  end
end
