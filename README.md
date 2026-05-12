# Cannery

![old screenshot](https://codeberg.org/shibao/cannery/raw/branch/stable/home.png)

The self-hosted firearm tracker website.

* Easy to Use: Cannery lets you easily keep an eye on your ammo levels before
  and after range day
* Secure: Self-host your own instance, or use an instance from someone you
  trust. Your data stays with you, period
* Simple: Access from any internet-capable device

# Features

- Create containers to store your ammunition, and tag them with custom tags
- Add ammunition types to Cannery, and then ammo packs to your containers
- Stage ammo packs for range day and track your usage with shot records
- Invitations via invite tokens or public registration

# Installation

1. Install [Docker Engine with Docker Compose v2](https://docs.docker.com/compose/install/) (or Docker Desktop).
1. Copy `.env.example` to `.env` and set your production values:
   ```sh
   cp .env.example .env
   ```
1. Generate a strong `SECRET_KEY_BASE` and paste it into `.env`:
   ```sh
   openssl rand -base64 64 | tr -d '\n'
   ```
1. Start the stack:
   ```sh
   docker compose up -d --build
   ```
1. Open `http://localhost:4000` for first-time setup.

The first created user will be created as an admin.

## Reverse proxy

Set `HOST` in `.env` to your public hostname (for example, `cannery.example.com`) and reverse proxy to `http://cannery:4000` if your proxy is on the same Docker network.

The included compose file binds the app to `127.0.0.1:4000` by default for safer local exposure. If you need direct LAN/public access, update the binding in `docker-compose.yml`.

# Configuration

You can use the following environment variables to configure Cannery in
[`.env`](./.env.example).

- `HOST`: External url to generate links with. Must be set with your hosted
  domain name! I.e. `cannery.mywebsite.tld`
- `PORT`: Internal port to bind to. Defaults to `4000`.
- `POSTGRES_USER`: PostgreSQL username. Defaults to `postgres`.
- `POSTGRES_PASSWORD`: PostgreSQL password.
- `POSTGRES_DB`: PostgreSQL database name. Defaults to `cannery`.
- `DATABASE_URL`: Full database URL. Keep this in sync with the PostgreSQL vars above.
- `ECTO_IPV6`: If set to `true`, Ecto should use ipv6 to connect to PostgreSQL.
  Defaults to `false`.
- `POOL_SIZE`: Controls the pool size to use with PostgreSQL. Defaults to `10`.
- `SECRET_KEY_BASE`: Secret key base used to sign cookies. Must be randomly generated and set for server startup.
- `REGISTRATION`: Controls if user sign-up should be invite only or set to
  public. Set to `public` to enable public registration. Defaults to `invite`.
- `LOCALE`: Sets a custom default locale. Defaults to `en_US`
  - Available options: `en_US`, `de`, `fr` and `es`
- `SMTP_HOST`: The url for your SMTP email provider. Must be set
- `SMTP_PORT`: The port for your SMTP relay. Defaults to `587`.
- `SMTP_USERNAME`: The username for your SMTP relay. Must be set!
- `SMTP_PASSWORD`: The password for your SMTP relay. Must be set!
- `SMTP_SSL`: Set to `true` to enable SSL for emails. Defaults to `false`.
- `EMAIL_FROM`: Sets the sender email in sent emails. Defaults to
  `no-reply@HOST` where `HOST` was previously defined.
- `EMAIL_NAME`: Sets the sender name in sent emails. Defaults to "Cannery".

# Upgrading the Database

Typically, PostgreSQL updates can improve the performance of the database, and
the cannery app. However, these require some additional maintenance. While the
typical method is to manually dump and restore the database using the `pg_dump`
tool, I recommend using the
[pgautoupgrade tool](https://github.com/pgautoupgrade/docker-pgautoupgrade),
which can perform this for you automatically. In the `docker-compose.yml` file,
you can do this easily by switching the `image:` value from for example,
`postgres:17-alpine` to `pgautoupgrade/pgautoupgrade:17-alpine` and rerun
`docker compose up -d`. This will automatically migrate your database to
Postgres 17, and then you can switch back to the original `postgres:17-alpine` image
for additional performance, or keep using the upgrade image if you'd like.

# Contribution

Contributions are greatly appreciated, no ability to code needed! You can browse
the [Contribution
Guide](https://codeberg.org/shibao/cannery/src/branch/stable/CONTRIBUTING.md)
to learn more.

I can be contacted at [shibao@shibao.dev](mailto:shibao@shibao.dev). Thank you!

# License

Cannery is licensed under AGPLv3 or later. A copy of the latest version of the
license can be found at
[LICENSE.md](https://codebe
rg.org/shibao/cannery/src/branch/stable/LICENSE.md).

# Links

- [Website](https://cannery.app): Project website
- [Codeberg](https://codeberg.org/shibao/cannery): Main repo, feature
  requests and bug reports
- [Weblate](https://translate.codeberg.org/engage/cannery/): Contribute to
  translations!

---

[![translation status](https://translate.codeberg.org/widgets/cannery/-/svg-badge.svg)](https://translate.codeberg.org/engage/cannery/)
