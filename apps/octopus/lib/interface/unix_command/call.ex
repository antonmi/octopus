defmodule Octopus.Interface.UnixCommand.Call do
  def call(input, config) do
    command = config["command"]

    case Rambo.run(command, input) do
      {:ok, %Rambo{err: err, out: out, status: status}} ->
        case status do
          0 ->
            {:ok, out}

          _not_zero ->
            {:error, err}
        end

      {:error, error} ->
        {:error, inspect(error)}
    end
  end
end
