defmodule SwiftApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :swift_api,
      version: "0.2.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :timex],
      mod: {SwiftApi.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.3.0"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.1"},
      {:mock, "~> 0.3.0", only: :test},
      {:credo, ">= 0.0.0", only: :dev}
    ]
  end
end
