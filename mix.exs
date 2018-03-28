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
      version: "1.0.0",
      elixir: "~> 1.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test],
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev},
      {:ex_spec, "~> 2.0", only: :test},
      {:jason, "~> 1.0", only: :test},
      {:excoveralls, "~> 0.8", only: :test}
    ]
  end
end
