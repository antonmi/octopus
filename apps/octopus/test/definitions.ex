defmodule Octopus.Test.Definitions do
  def unix_command do
    %{
      "type" => "unix_command",
      "name" => "ipcalc",
      "interface" => %{
        "for_ip" => %{
          "call" => %{
            "command" => "/usr/local/bin/ipcalc",
            # call opts
            "opts" => %{}
          },
          "input" => %{
            "args" => %{"ip" => nil},
            "transform" => ":ip"
          },
          # json
          "output" => "binary"
        },
        "for_ip_with_mask" => %{
          "call" => %{
            "command" => "/usr/local/bin/ipcalc"
          },
          "input" => %{
            "args" => %{
              "ip" => nil,
              "mask" => nil
            },
            "transform" => ":ip/:mask"
          },
          "output" => "binary"
        }
      }
    }
  end

  def json_api do
    %{
      "type" => "json_api",
      "name" => "agify",
      "interface" => %{
        "age_for_name" => %{
          "call" => %{
            "url" => "https://api.agify.io/",
            "method" => "GET"
          },
          "input" => %{
            "args" => %{
              "name" => nil
            }
          },
          "output" => "map"
        }
      }
    }
  end

  def json_api do
    %{
      "type" => "json_api",
      "name" => "agify",
      "interface" => %{
        "age_for_name" => %{
          "call" => %{
            "url" => "https://api.agify.io/",
            "method" => "GET"
          },
          "input" => %{
            "args" => %{
              "name" => nil
            }
          },
          "output" => "map"
        }
      }
    }
  end
end
