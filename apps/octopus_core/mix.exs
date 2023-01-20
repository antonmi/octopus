defmodule OctopusCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus_core,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:eex, :logger],
      mod: {Octopus.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_json_schema, "~> 0.9"},
      {:jason, "~> 1.4"}
    ]
  end
end
