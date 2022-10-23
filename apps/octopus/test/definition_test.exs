defmodule Octopus.DefinitionTest do
  use ExUnit.Case
  alias Octopus.Definition
  alias Octopus.Definition.Storage

  @cli_definition %{
    type: "cli",
    name: "ipcalc",
    command: "/usr/local/bin/ipcalc",
    interface: %{
      for_ip: %{
        input: %{
          args: %{ip: nil},
          transform: ":ip"
        },
        # json
        output: :binary
      },
      for_ip_with_mask: %{
        input: %{
          args: %{
            ip: nil,
            mask: nil
          },
          transform: ":ip/:mask"
        }
      }
    }
  }

  @json_api_definition %{
    type: "json_api",
    name: "agify",
    url: "https://api.agify.io/",
    method: "GET"
  }

  @code_module_definition %{
    type: "code",
    name: "my_module",
    code: """
      defmodule TheModule do
        def call(number) do
          number + 1
        end
      end
    """
  }

  @code_function_definition %{
    type: "code",
    name: "my_function",
    code: """
      def call(number) do
        number + 1
      end
    """
  }

  test "cli definition" do
    {:ok, code} = Definition.define(@cli_definition)

    {:ok, string} = Octopus.Service.Ipcalc.for_ip(%{ip: "192.168.0.1"})
    assert String.contains?(string, "Address:   192.168.0.1")

    {:ok, string} = Octopus.Service.Ipcalc.for_ip(%{"ip" => "192.168.0.1"})
    assert String.contains?(string, "Address:   192.168.0.1")

    {:ok, string} = Octopus.Service.Ipcalc.for_ip_with_mask(%{ip: "192.168.0.1", mask: "24"})
    assert String.contains?(string, "Address:   192.168.0.1")
  end

  test "json_api definition" do
    {:ok, code} = Definition.define(@json_api_definition)
    assert String.starts_with?(code, "defmodule Octopus.Service.Agify")
    assert {:ok, map} = Octopus.Service.Agify.call(%{name: "Anton"})
    assert map["name"] == "Anton"
  end

  test "code module definition" do
    {:ok, code} = Definition.define(@code_module_definition)
    assert String.starts_with?(code, "defmodule Octopus.Service.MyModule")
    assert Octopus.Service.MyModule.TheModule.call(1) == 2
  end

  test "code function definition" do
    {:ok, code} = Definition.define(@code_function_definition)
    assert String.starts_with?(code, "defmodule Octopus.Service.MyFunction")
    assert Octopus.Service.MyFunction.call(1) == 2
  end
end
