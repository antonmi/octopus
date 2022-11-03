defmodule Octopus.Interface.XmlApi.Call do
  alias Octopus.Utils

  defdelegate call(params, config), to: Octopus.Interface.JsonApi.Call
end
