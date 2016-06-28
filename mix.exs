defmodule Fuzzyurl.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fuzzyurl,
      description: ~S"""
        Fuzzyurl is a library for non-strict parsing, construction, and
        fuzzy-matching of URLs.
      """,
      package: [
        maintainers: ["pete gamache"],
        licenses: ["Apache 2.0"],
        links: %{"GitHub" => "https://github.com/gamache/fuzzyurl.ex"}
      ],
      version: "0.9.0",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test],
      deps: deps
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.10", only: :dev},
      {:ex_spec, github: "appcues/ex_spec", tag: "1.1.0-elixir13", only: :test},
      {:excoveralls, "~> 0.4", only: :test},
      {:poison, "~> 1.5", only: :test},
    ]
  end
end
