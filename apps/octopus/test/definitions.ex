defmodule Octopus.Test.Definitions do
  def unix_command do
    %{
      "type" => "unix_command",
      "name" => "ipcalc",
      "interface" => %{
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
          },
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
      "type" => "json_api",
      "name" => "json_server",
      "run" => %{
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

  #  def local_process do
  #    %{
  #      "type" => "code",
  #      "name" => "json_server",
  #      "run" => %{
  #        "command": "node /Users/anton.mishchukkloeckner.com/.asdf/installs/nodejs/16.2.0/.npm/bin/json-server -w db.json"
  #      },
  #      "interface" => %{
  #        "posts" => %{
  #          "call" => %{
  #            "url" => "http://localhost:3000/",
  #            "path" => "posts",
  #            "method" => "GET"
  #          },
  #          "input" => %{
  #            "args" => %{}
  #          },
  #          "output" => "map"
  #        },
  #        "post" => %{
  #          "call" => %{
  #            "url" => "http://localhost:3000",
  #            "path" => "posts/:id",
  #            "method" => "GET"
  #          },
  #          "input" => %{
  #            "args" => %{
  #              "id" => nil
  #            }
  #          },
  #          "output" => "map"
  #        }
  #      }
  #    }
  #  end
end
