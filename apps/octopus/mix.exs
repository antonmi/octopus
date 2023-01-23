defmodule OctopusOld.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus,
      version: "0.1.1",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/antonmi/octopus",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  defp description do
    "Declarative interface mapping"
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md),
      maintainers: ["Anton Mishchuk"],
      licenses: ["MIT"],
      links: %{"github" => "https://github.com/antonmi/octopus"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rambo, "0.3.4"},
      {:finch, "~> 0.13"},
      {:postgrex, "~> 0.16.5"},
      {:jason, "~> 1.4"},
      {:sweet_xml, "~> 0.7.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
