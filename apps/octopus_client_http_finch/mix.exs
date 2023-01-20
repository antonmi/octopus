defmodule OctopusClientHttpFinch.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus_client_http_finch,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:octopus_core, in_umbrella: true},
      {:finch, "~> 0.13"},
      {:jason, "~> 1.4"},
      {:bypass, "~> 2.1", only: :test}
    ]
  end
end
