defmodule Octopus.UtilsTest do
  use ExUnit.Case
  alias Octopus.Utils

  describe "eval_template" do
    test "<%= args[\"ip\"] %>/<%= args[\"mask\"] %>" do
      template = "<%= args[\"ip\"] %>/<%= args[\"mask\"] %>"

      args = %{
        "ip" => "1.2.3.4",
        "mask" => "24"
      }

      assert Utils.eval_template(template, args, false) == "1.2.3.4/24"
    end

    test "with eval true" do
      template = "[\"<%= args[\"name\"] %>\", <%= args[\"age\"] %>]"

      args = %{
        "name" => "Anton",
        "age" => 123
      }

      assert Utils.eval_template(template, args, true) == ["Anton", 123]
    end
  end
end
