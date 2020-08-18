defmodule ExConfigEldap.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_config_eldap,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Types for `ExConfig` to support `:eldap` Erlang library.",
      package: package(),
      name: "ExConfigEldap",
      source_url: "https://github.com/sega-yarkin/ex_config_eldap",
      dialyzer: [
        plt_add_apps: [:erts, :kernel, :stdlib, :eldap],
        ignore_warnings: ".dialyzer.ignore",
        flags: [:error_handling, :underspecs, :overspecs, :unmatched_returns, :unknown],
      ],
    ]
  end

  def application do
    [extra_applications: [:eldap]]
  end

  defp deps do
    [
      {:ex_config, "~> 0.1"},
      {:nimble_parsec, "~> 0.6"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{github: "https://github.com/sega-yarkin/ex_config_eldap"},
      files: ~w(mix.exs README.md LICENSE lib),
    ]
  end
end
