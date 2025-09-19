defmodule Mockery.Mixfile do
  use Mix.Project

  @version "2.5.0"
  @description "Simple mocking library for asynchronous testing."

  def project do
    [
      app: :mockery,
      deps: deps(),
      description: @description,
      docs: docs(),
      elixir: "~> 1.15",
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
      {:beam_inspect, "~> 0.1.2", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.13", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "EXAMPLES.md", "CHANGELOG.md"],
      main: "readme",
      skip_code_autolink_to: ["Mockery.Proxy.MacroProxy"],
      source_ref: @version,
      default_group_for_doc: fn meta ->
        if is_binary(meta[:deprecated]), do: "Deprecated"
      end
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: ["Tobiasz Małecki"],
      licenses: ["Apache-2.0"],
      files: ["lib", "mix.exs", ".formatter.exs", "README*", "LICENSE", "CHANGELOG*"],
      links: %{
        "GitHub" => "https://github.com/appunite/mockery",
        "Changelog" => "https://hexdocs.pm/mockery/changelog.html"
      }
    ]
  end
end
