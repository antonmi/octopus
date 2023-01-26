defmodule OctopusAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus_agent,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {OctopusAgent.Application, []}
    ]
  end

  defp deps do
    [
      {:octopus, in_umbrella: true},
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
