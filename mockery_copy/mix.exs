defmodule Mockery.Copy.Mixfile do
  use Mix.Project

  @version "0.1.0-alpha.0"
  @description "Support package for :mockery"

  def project do
    [
      app: :mockery_copy,
      deps: deps(),
      description: @description,
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.15",
      name: "Mockery.Copy",
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

  defp dialyzer do
    config = [
      plt_add_apps: []
    ]

    if System.get_env("CI") do
      Keyword.put(config, :plt_file, {:no_warn, "priv/plts/project.plt"})
    else
      config
    end
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      skip_code_autolink_to: [],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      source_ref: "copy-#{@version}",
      source_url_pattern:
        "https://github.com/appunite/mockery/blob/copy-#{@version}/mockery_copy/%{path}#L%{line}"
    ]
  end

  defp package do
    [
      maintainers: ["Tobiasz Małecki"],
      licenses: ["Apache-2.0"],
      files: ["lib", "mix.exs", ".formatter.exs", "README*", "LICENSE"],
      links: %{
        "GitHub" => "https://github.com/appunite/mockery",
        "Changelog" => "https://hexdocs.pm/mockery_copy/changelog.html",
        "Mockery" => "https://hex.pm/packages/mockery"
      }
    ]
  end
end
