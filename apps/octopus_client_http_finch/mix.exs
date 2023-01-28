defmodule OctopusClientHttpFinch.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus_client_http_finch,
      version: "0.2.0",
      elixir: "~> 1.12",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/antonmi/octopus/tree/main/apps/octopus_client_http_finch",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OctopusClientHttpFinch.Application, []}
    ]
  end

  defp description do
    "Octopus HTTP client based on Finch"
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md),
      maintainers: ["Anton Mishchuk"],
      licenses: ["MIT"],
      links: %{
        "github" => "https://github.com/antonmi/octopus/tree/main/apps/octopus_client_http_finch"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:octopus, in_umbrella: true, only: [:dev, :test]},
      {:finch, "~> 0.13"},
      {:jason, "~> 1.4"},
      {:bypass, "~> 2.1", only: :test},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end
end
