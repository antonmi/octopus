defmodule Octopus.UtilsTest do
  use ExUnit.Case
  alias Octopus.Utils

  describe "eval_pattern" do
    test ":ip/:mask" do
      args = %{
        "ip" => "1.2.3.4",
        "mask" => "24"
      }

      assert Utils.eval_pattern(":ip", args) == "1.2.3.4"
      assert Utils.eval_pattern(":ip/:mask", args) == "1.2.3.4/24"
    end

    test "posts/:id" do
      args = %{
        "id" => 42
      }

      assert Utils.eval_pattern("/posts", args) == "/posts"
      assert Utils.eval_pattern("/posts/:id", args) == "/posts/42"
    end
  end
end
