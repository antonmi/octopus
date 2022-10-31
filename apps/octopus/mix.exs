defmodule OctopusCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :octopus,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex],
      mod: {Octopus.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rambo, "0.3.4"},
      {:finch, "~> 0.13"},
      {:postgrex, "~> 0.16.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
