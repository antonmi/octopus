defmodule OctopusAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus_agent,
      version: "0.3.0",
      elixir: "~> 1.14",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/antonmi/octopus/tree/main/apps/octopus_agent",
      deps: deps()
    ]
  end

  def application do
    [
      mod: {OctopusAgent.Application, []}
    ]
  end

  defp description do
    "Web Interface for Octopus"
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md),
      maintainers: ["Anton Mishchuk"],
      licenses: ["MIT"],
      links: %{"github" => "https://github.com/antonmi/octopus/tree/main/apps/octopus_agent"}
    ]
  end

  defp deps do
    [
      {:octopus, in_umbrella: true, only: [:dev, :test]},
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end
end
