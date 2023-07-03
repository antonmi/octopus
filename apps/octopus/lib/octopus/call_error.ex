defmodule Octopus.CallError do
  defexception [:step, :error, :message, :stacktrace]

  @type t :: %__MODULE__{
          step: :input | :prepare | :call | :transorm | :output | :error,
          error: any(),
          message: String.t(),
          stacktrace: String.t()
        }

  def message(%__MODULE__{} = error) do
    [error.step, error.message]
    |> Enum.join(" - ")
  end
end
