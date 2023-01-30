defmodule Octopus.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus,
      version: "0.4.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      source_url: "https://github.com/antonmi/octopus",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:eex, :logger],
      mod: {Octopus.Application, []}
    ]
  end

  defp description do
    "Declarative Interface Translation"
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md),
      maintainers: ["Anton Mishchuk"],
      licenses: ["MIT"],
      links: %{"github" => "https://github.com/antonmi/octopus"}
    ]
  end

  defp deps do
    [
      {:ex_json_schema, "~> 0.9"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end
end
