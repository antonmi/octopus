defmodule Octopus.Interface.Code do
  use Octopus.Interface,
    input: __MODULE__.Input,
    call: __MODULE__.Call,
    output: __MODULE__.Output
end
