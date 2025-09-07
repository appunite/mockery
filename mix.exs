defmodule Mockery.Mixfile do
  use Mix.Project

  @version "2.3.4"

  def project do
    [
      app: :mockery,
      deps: deps(),
      description: description(),
      docs: [
        extras: ["README.md", "EXAMPLES.md", "CHANGELOG.md"],
        main: "readme",
        source_ref: @version
      ],
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      source_url: "https://github.com/appunite/mockery",
      version: @version
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:beam_inspect, "~> 0.1.1", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:ex_doc, "~> 0.13", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Simple mocking library for asynchronous testing."
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: ["Tobiasz Małecki"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/appunite/mockery",
        "Changelog" => "https://hexdocs.pm/mockery/changelog.html"
      }
    ]
  end
end
