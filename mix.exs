defmodule Mockery.Mixfile do
  use Mix.Project

  @version "2.0.1"

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
      {:credo, "~> 0.8", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:excoveralls, "~> 0.7", only: :test},
      {:ex_doc, "~> 0.13", only: :dev, runtime: false}
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
      links: %{
        "GitHub" => "https://github.com/appunite/mockery",
        "Changelog" => "https://hexdocs.pm/mockery/changelog.html"
      }
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.json": :test
    ]
  end
end
