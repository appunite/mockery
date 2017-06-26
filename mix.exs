defmodule Mockery.Mixfile do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :mockery,
      deps: deps(),
      description: description(),
      docs: docs(),
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      package: package(),
      version: @version
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.13", only: :dev}
    ]
  end

  defp description do
    "Simple mocking library"
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp package do
    [
      name: :mockery,
      files: ~w(lib mix.exs README.md LICENSE),
      maintainers: ["Tobiasz Małecki"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/amatalai/mockery"}
    ]
  end
end
