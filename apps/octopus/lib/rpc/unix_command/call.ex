defmodule Octopus.Rpc.UnixCommand.Call do
  def call(input, config) do
    command = config["command"]
    {:ok, %Rambo{err: err, out: out, status: status}} = Rambo.run(command, input)

    case status do
      0 ->
        {:ok, out}

      _not_zero ->
        {:error, err}
    end
  end
end
