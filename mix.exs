defmodule Hermod.Mixfile do
  use Mix.Project

  def project do
    [app: :Hermod,
     version: "0.0.3",
     elixir: ">= 1.0.0",
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      mod: { Hermod, [] },
      applications: [:cowboy, :ranch, :logger, :redix_pubsub]
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
  # Type `mix help deps` for more examples and options
  defp deps() do
    [ { :cowboy, github: "ninenines/cowboy", tag: "2.0.0-pre.10" },
      { :redix_pubsub, ">= 0.0.0" },
      { :poison, "~> 3.1" },
      { :env_helper, "~> 0.0.1" },
      { :distillery, "~> 1.4", runtime: false } ]
  end
end
