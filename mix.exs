
defmodule Promenade.Mixfile do
  use Mix.Project

  def project do
    [
      app: :promenade,
      version: "0.1.3",
      elixir: "~> 1.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [
        :logger,
        :plug,
        :cowboy,
        :quantile_estimator
      ],
      mod: {Promenade, []},
      env: [
        http_port: 8080,
        udp_port: 8126,
      ],
    ]
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
      exrm: "~> 1.0.2",
      exactor: "~> 2.2.0",
      plug: "~> 1.1.2",
      cowboy: "~> 1.0.0",
      quantile_estimator: [
        git: "https://github.com/jemc/quantile_estimator.git",
        sha: "37f4d6cc5808dc6c571563c3b76ca1a71b7cff3e",
      ],
    ]
  end
end
