defmodule Octopus.Test.Definitions do
  def cli do
    %{
      "name" => "ipcalc",
      "interface" => %{
        "type" => "cli",
        "for_ip" => %{
          "call" => %{
            "command" => "/usr/local/bin/ipcalc",
            "opts" => %{}
          },
          "input" => %{
            "args" => %{
              "ip" => nil
            },
            "transform" => ":ip"
            # actually here can be EEx template
            # "<%= args["ip"] %>"
            # very powerful!
          },
          # The same for output
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
            # EEx template!
          },
          "output" => "binary"
          # EEx template!
        }
      }
    }
  end

  def json_api do
    %{
      "name" => "agify",
      "interface" => %{
        "type" => "json_api",
        "age_for_name" => %{
          "call" => %{
            "url" => "https://api.agify.io",
            "path" => "/",
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

  def json_server do
    %{
      "name" => "json_server.v1",
      "execution" => %{
        "type" => "process",
        "start" => %{
          "command" => "node",
          "args" => [
            "/Users/anton.mishchukkloeckner.com/.asdf/installs/nodejs/16.2.0/.npm/bin/json-server",
            "-w",
            "db.json"
          ]
        },
        "ping" =>
          %{
            # TODO
          }
      },
      "interface" => %{
        "type" => "json_api", # it maps to module Octopus.Interface.JsonApi
        "posts" => %{
          "call" => %{
            "url" => "http://localhost:3000",
            "path" => "/posts",
            "method" => "GET"
          },
          "input" => %{
            "args" => %{}
          },
          "output" => "map"
        },
        "post" => %{
          "call" => %{
            "url" => "http://localhost:3000",
            "path" => "/posts/:id",
            "method" => "GET"
          },
          "input" => %{
            "args" => %{
              "id" => nil
            }
          },
          "output" => "map"
        }
      }
    }
  end

end
