defmodule Octopus.GithubServiceTest do
  use ExUnit.Case, async: true
  alias Octopus

  def read_definition() do
    path = Path.expand("../definitions", __ENV__.file)

    File.read!("#{path}/github.json")
  end

  setup do
    {:ok, "github"} = Octopus.define(read_definition())
    {:ok, _state} = Octopus.start("github")

    on_exit(fn -> Octopus.delete("github") end)
  end

  test "find_users" do
    {:ok, results} = Octopus.call("github", "find_users", %{"username" => "antonmi"})
    assert %{"total_count" => number, "usernames" => usernames} = results
    assert number > 0
    assert Enum.member?(usernames, "antonmi")
  end

  test "get_followers" do
    {:ok, result} = Octopus.call("github", "get_followers", %{"username" => "antonmi"})
    assert is_list(result["followers"])
  end

  #  test "get_followers with client error" do
  #
  #    {:ok, result} = Octopus.call("github", "get_followers", %{"username" => "the-is-no-such-username"})
  #    |> IO.inspect
  #    assert is_list(result["followers"])
  #  end
end
