defmodule Mockery.Mixfile do
  use Mix.Project

  @source_url "https://github.com/appunite/mockery"
  @version "2.3.1"

  def project do
    [
      app: :mockery,
      deps: deps(),
      docs: docs(),
      dialyzer: [
        flags: [
          :error_handling,
          :race_conditions,
          :underspecs,
          :unmatched_returns
        ],
        plt_add_apps: [:ex_unit, :mix]
      ],
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.json": :test
      ],
      test_coverage: [tool: ExCoveralls],
      version: @version
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:beam_inspect, "~> 0.1.1", only: :dev, runtime: false},
      {:credo, "~> 0.8", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:excoveralls, "~> 0.7", only: :test, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      description: "Simple mocking library for asynchronous testing.",
      maintainers: ["Tobiasz Małecki"],
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "https://hexdocs.pm/mockery/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md",
        {:"LICENSE", [title: "License"]},
        "README.md",
        "EXAMPLES.md",
        "MIGRATION_TO_OTP21.md"
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      formatters: ["html"]
    ]
  end
end
