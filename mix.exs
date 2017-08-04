defmodule Mockery.Mixfile do
  use Mix.Project

  @version "1.1.0"

  def project do
    [
      app: :mockery,
      deps: deps(),
      description: description(),
      docs: docs(),
      elixir: "~> 1.1",
      elixirc_paths: elixirc_paths(Mix.env),
      package: package(),
      preferred_cli_env: preferred_cli_env(),
      test_coverage: [tool: ExCoveralls],
      version: @version
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:excoveralls, "~> 0.7", only: :test},
      {:ex_doc, "~> 0.13", only: :dev}
    ]
  end

  defp description do
    "Simple mocking library for asynchronous testing."
  end

  defp docs do
    [
      extras: ["README.md", "EXAMPLES.md", "CHANGELOG.md"],
      main: "readme"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp package do
    [
      name: :mockery,
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE),
      maintainers: ["Tobiasz Małecki"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/appunite/mockery"}
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.travis": :test
    ]
  end
end
