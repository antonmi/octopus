defmodule Octopus.CallError do
  defexception [:type, :message, :stacktrace]

  @type t :: %__MODULE__{
          type: :input | :prepare | :call | :transorm | :output,
          message: String.t()
        }

  def message(%__MODULE__{} = error) do
    [error.type, error.message]
    |> Enum.join(" - ")
  end
end
