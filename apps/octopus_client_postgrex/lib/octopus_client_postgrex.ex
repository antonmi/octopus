defmodule OctopusClientPostgrex do
  defmodule State do
    @moduledoc false
    defstruct [:host, :port, :database, :username, :password, :name, :pid]

    @type t :: %__MODULE__{
            host: String.t(),
            port: String.t(),
            database: String.t(),
            username: String.t(),
            password: String.t(),
            name: atom(),
            pid: pid()
          }
  end

  defmodule Request do
    @moduledoc false
    defstruct statement: nil, params: [], opts: []

    @type t :: %__MODULE__{
            statement: String.t(),
            params: [],
            opts: []
          }
  end

  defmodule Response do
    @moduledoc false
    defstruct columns: nil, num_rows: 0, rows: nil

    @type t :: %__MODULE__{
            columns: [String.t()] | nil,
            num_rows: integer(),
            rows: [[term()] | binary()] | nil
          }
  end

  defmodule Adapter do
    def call(args, configs, state) do
      OctopusClientPostgrex.call(args, configs, state)
    end
  end

  def start(args, configs) do
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

    state = %State{
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

  def call(args, configs, state) do
    statement = args["statement"] || configs["statement"]
    params = args["params"] || configs["params"] || []
    opts = opts_to_keyword_list(args["opts"] || configs["opts"] || %{})

    case Postgrex.query(state.name, statement, params, opts) do
      {:ok, %Postgrex.Result{columns: columns, num_rows: num_rows, rows: rows}} ->
        {:ok, %{"columns" => columns, "num_rows" => num_rows, "rows" => rows}}

      {:error, error} ->
        {:error, error}
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
