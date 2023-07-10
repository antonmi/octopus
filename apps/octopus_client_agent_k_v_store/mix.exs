defmodule OctopusClientAgentKVStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus_client_agent_k_v_store,
      version: "0.1.0",
      elixir: "~> 1.14",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/antonmi/octopus/tree/main/apps/octopus_client_agent_k_v_store",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OctopusClientAgentKVStore.Application, []}
    ]
  end

  defp description do
    "Octopus key-value storage based on Agent"
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md),
      maintainers: ["Anton Mishchuk"],
      licenses: ["MIT"],
      links: %{
        "github" => "https://github.com/antonmi/octopus/tree/main/apps/octopus_client_agent_k_v_store"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:octopus, in_umbrella: true, only: [:dev, :test]},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end
end
