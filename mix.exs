defmodule Mockery.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :mockery,
      build_embedded: Mix.env == :prod,
      deps: deps(),
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      version: @version
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
