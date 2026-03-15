import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/cannery start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :cannery, CanneryWeb.Endpoint, server: true
end

config :cannery, CanneryWeb.HTMLHelpers, shibao_mode: System.get_env("SHIBAO_MODE") == "true"

config :cannery, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

# Set default locale
config :gettext, :default_locale, System.get_env("LOCALE", "en_US")

maybe_ipv6 = if System.get_env("ECTO_IPV6") == "true", do: [:inet6], else: []

database_url =
  if config_env() == :test do
    System.get_env(
      "TEST_DATABASE_URL",
      "ecto://postgres:postgres@localhost/cannery_test#{System.get_env("MIX_TEST_PARTITION")}"
    )
  else
    System.get_env("DATABASE_URL", "ecto://postgres:postgres@cannery-db/cannery")
  end

host =
  System.get_env("HOST") ||
    raise "No hostname set! Must be the domain and tld like `cannery.bubbletea.dev`."

interface =
  if config_env() in [:dev, :test],
    do: {0, 0, 0, 0},
    else: {0, 0, 0, 0, 0, 0, 0, 0}

config :cannery, Cannery.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
  socket_options: maybe_ipv6

config :cannery, CanneryWeb.Endpoint,
  url: [scheme: "https", host: host, port: 443],
  http: [
    # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
    # for details about using IPv6 vs IPv4 and loopback vs public addresses.
    ip: interface,
    port:
      if config_env() == :test do
        String.to_integer(System.get_env("TEST_PORT", "4001"))
      else
        String.to_integer(System.get_env("PORT", "4000"))
      end
  ],
  server: config_env() != :test

if config_env() in [:dev, :prod] do
  config :cannery, Cannery.Accounts, registration: System.get_env("REGISTRATION", "invite")
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: priv/random.sh
      """

  config :cannery, CanneryWeb.Endpoint, secret_key_base: secret_key_base

  # Automatically apply migrations
  config :cannery, Cannery.Application, automigrate: true

  smtp_host = System.get_env("SMTP_HOST") || raise("No SMTP_HOST set!")

  # Set up SMTP settings
  config :cannery, Cannery.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: smtp_host,
    port: System.get_env("SMTP_PORT", "587") |> String.to_integer(),
    username: System.get_env("SMTP_USERNAME") || raise("No SMTP_USERNAME set!"),
    password: System.get_env("SMTP_PASSWORD") || raise("No SMTP_PASSWORD set!"),
    ssl: System.get_env("SMTP_SSL") == "true",
    tls: :always,
    auth: :always,
    no_mx_lookups: false,
    tls_options: [
      versions: [:"tlsv1.2", :"tlsv1.3"],
      verify: :verify_peer,
      cacerts: :public_key.cacerts_get(),
      server_name_indication: String.to_charlist(smtp_host),
      depth: 99,
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ],
    email_from: System.get_env("EMAIL_FROM", "no-reply@#{System.get_env("HOST")}"),
    email_name: System.get_env("EMAIL_NAME", "Cannery")

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :cannery, CanneryWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.
end
