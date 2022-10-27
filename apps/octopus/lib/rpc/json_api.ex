defmodule Octopus.Rpc.JsonApi do
  use Octopus.Rpc,
      input: __MODULE__.Input,
      call: __MODULE__.Call,
      output: __MODULE__.Output
end
