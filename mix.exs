defmodule Cannery.MixProject do
  use Mix.Project

  def project do
    [
      app: :cannery,
      version: "0.9.20",
      elixir: "1.19.5",
      elixirc_options: [ignore_module_conflict: true],
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      consolidate_protocols: Mix.env() not in [:dev, :test],
      preferred_cli_env: ["test.all": :test],
      # ExDoc
      name: "Cannery",
      source_url: "https://codeberg.org/shibao/cannery",
      homepage_url: "https://codeberg.org/shibao/cannery",
      docs: [
        # The main page in the docs
        main: "README.md",
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ],
      authors: ["shibao"],
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs"]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Cannery.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon, :crypto]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def cli do
    [preferred_envs: ["test.all": :test]]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bandit, "~> 1.5"},
      {:bcrypt_elixir, "~> 3.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dns_cluster, "~> 0.2"},
      {:ecto_psql_extras, "~> 0.6"},
      {:ecto_sql, "~> 3.6"},
      {:eqrcode, "~> 0.2"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:ex_heroicons, "~> 3.1.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:gen_smtp, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.5",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "~> 1.2"},
      {:oban, "~> 2.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.6.1", only: :dev},
      {:phoenix_live_view, "~> 1.1.27"},
      {:phoenix, "~> 1.8.5"},
      {:plug_cowboy, "~> 2.8.0"},
      {:postgrex, ">= 0.0.0"},
      {:swoosh, "~> 1.6"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.0"},
      {:tidewave, "~> 0.5", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "assets.build": ["tailwind cannery", "esbuild cannery"],
      "assets.deploy": [
        "tailwind cannery --minify",
        "esbuild cannery --minify",
        "phx.digest"
      ],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "format.all": [
        "assets.build",
        "format",
        "gettext.extract --merge",
        "gettext.merge --no-fuzzy priv/gettext"
      ],
      "test.all": [
        "assets.build",
        "dialyzer",
        "credo --strict",
        "format --check-formatted",
        "gettext.extract --check-up-to-date",
        "ecto.drop --quiet",
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "test"
      ],
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
