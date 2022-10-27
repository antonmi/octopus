ExUnit.start()

path =
  "../../.."
  |> Path.expand(__ENV__.file)
  |> Path.join("octopus/test")

Code.compile_file("definitions.ex", path)
