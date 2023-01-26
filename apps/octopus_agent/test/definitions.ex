defmodule OctopusAgent.Test.Definitions do
  def read(file) do
    path = Path.expand("../definitions", __ENV__.file)

    "#{path}/#{file}"
    |> File.read!()
    |> Jason.decode!()
    |> Jason.encode!()
  end

  def read_from_octopus(file) do
    path = Path.expand("../../../octopus/test/definitions", __ENV__.file)

    "#{path}/#{file}"
    |> File.read!()
    |> Jason.decode!()
    |> Jason.encode!()
  end
end
