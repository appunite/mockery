defmodule Mockery.Mixfile do
  use Mix.Project

  @version "3.0.0-alpha.0"
  @description "Simple mocking library for asynchronous testing."

  def project do
    [
      app: :mockery,
      deps: deps(),
      description: @description,
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Mockery",
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
      {:mockery_macro,
       github: "amatalai/mockery", branch: "split", sparse: "mockery_macro", optional: true},

      # development
      {:beam_inspect, "~> 0.1.2", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.13", only: :dev, runtime: false}
    ]
  end

  defp dialyzer do
    config = [
      plt_add_apps: [:ex_unit],
      ignore_warnings: ".dialyzer_ignore.exs"
    ]

    if System.get_env("CI") do
      Keyword.put(config, :plt_file, {:no_warn, "priv/plts/project.plt"})
    else
      config
    end
  end

  defp docs do
    [
      extras: ["README.md", "EXAMPLES.md", "CHANGELOG.md"],
      main: "readme",
      skip_code_autolink_to: ["Mockery.Proxy"],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
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
