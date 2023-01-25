defmodule Octopus.GithubServiceTest do
  use ExUnit.Case, async: true
  alias Octopus

  def read_definition() do
    path = Path.expand("../definitions", __ENV__.file)

    File.read!("#{path}/github.json")
  end

  setup_all do
    {:ok, "github"} = Octopus.define(read_definition())

    {:ok, _state} =
      Octopus.init("github", %{
        "headers" => %{"Authorization" => "Bearer #{System.get_env("GITHUB_TOKEN")}"}
      })

    :ok
  end

  test "find_users" do
    {:ok, results} = Octopus.call("github", "find_users", %{"username" => "antonmi"})
    assert %{"total_count" => number, "users" => users} = results
    assert number > 0
    assert length(users) > 0
  end

  test "get_followers" do
    {:ok, result} = Octopus.call("github", "get_followers", %{"username" => "antonmi"})
    assert is_list(result["followers"])
  end
end
