defmodule OctopusClientPostgrex.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus_client_postgrex,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OctopusClientPostgrex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:octopus_core, in_umbrella: true},
      {:postgrex, "~> 0.16"}
    ]
  end
end
