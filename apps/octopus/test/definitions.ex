defmodule Octopus.Test.Definitions do
  def read_and_decode(file) do
    path = Path.expand("../definitions", __ENV__.file)

    "#{path}/#{file}"
    |> File.read!()
    |> Jason.decode!()
  end

  def cli do
    read_and_decode("cli.json")
  end

  def json_api do
    read_and_decode("json_api.json")
  end

  def json_server do
    read_and_decode("json_server.json")
  end

  def elixir_module do
    read_and_decode("elixir_module.json")
  end

  def postgres_sql do
    read_and_decode("postgres_sql.json")
  end

  def xml_api do
    read_and_decode("xml_api.json")
  end
end
