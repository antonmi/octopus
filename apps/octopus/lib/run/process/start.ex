defmodule Octopus.Run.Process.Start do
  def call(%{"command" => command, "args" => args}) do
    task =
      Task.async(fn ->
        do_run(command, args)
      end)

    Process.sleep(5_000)

    {:ok, task}
  end

  defp do_run(command, args) do
    case Rambo.run(command, args) do
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
