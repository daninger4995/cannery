defmodule Cannery.MixProject do
  use Mix.Project

  def project do
    [
      app: :cannery,
      version: "0.9.15",
      elixir: "1.18.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        # Added for OTP 28 bug https://github.com/jeremyjh/dialyxir/issues/561
        flags: [:no_opaque],
        plt_add_apps: [:ex_unit]
      ],
      consolidate_protocols: Mix.env() not in [:dev, :test],
      preferred_cli_env: ["test.all": :test],
      # ExDoc
      name: "Cannery",
      source_url: "https://gitea.bubbletea.dev/shibao/cannery",
      homepage_url: "https://gitea.bubbletea.dev/shibao/cannery",
      docs: [
        # The main page in the docs
        main: "README.md",
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ],
      authors: ["shibao"]
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
      {:floki, ">= 0.30.0", only: :test},
      {:gen_smtp, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:oban, "~> 2.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix, "~> 1.7.19"},
      {:plug_cowboy, "~> 2.7.0"},
      {:postgrex, ">= 0.0.0"},
      {:swoosh, "~> 1.6"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.0"}
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
