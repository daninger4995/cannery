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

1. Install [Docker Compose](https://docs.docker.com/compose/install/) or alternatively [Docker Desktop](https://docs.docker.com/desktop/) on your machine.
1. Copy the example [docker-compose.yml](https://codeberg.org/shibao/cannery/src/branch/stable/docker-compose.yml). into your local machine where you want.
   Bind mounts are created in the same directory by default.
1. Set the configuration variables in `docker-compose.yml`. You'll need to run
   `docker run -it shibaobun/cannery /app/priv/random.sh` to generate a new
   secret key base.
1. Use `docker-compose up` or `docker-compose up -d` to start the container!

The first created user will be created as an admin.

## Reverse proxy

Finally, reverse proxy to port `4000` of the container. If you're using a reverse proxy in another docker container, you can reverse proxy to `http://cannery:4000`. Otherwise, you'll need to modify the `docker-compose.yml` to bind the port to your local machine.

For instance, instead of
```
expose:
  - "4000"
```

use
```
ports:
  - "127.0.0.1:4000:4000"
```
and reverse proxy to `http://localhost:4000`.

If you don't already have a reverse proxy on the machine, I recommend installing
[Nginx Proxy Manager](https://nginxproxymanager.com/), which is a GUI for Nginx
that makes it easy to configure and modify as your hosting needs change. By
adding NPM to cannery's `docker-compose.yml`, you can avoid needing to bind any
ports to your machine and have all the internal traffic routed through the
generated docker network, which can be a bit more secure. The example
configuration is commented out in the `docker-compose.yml` file, and more
information can be found on their documentation
[here](https://nginxproxymanager.com/setup/).

# Configuration

You can use the following environment variables to configure Cannery in
[docker-compose.yml](https://codeberg.org/shibao/cannery/src/branch/stable/docker-compose.yml).

- `HOST`: External url to generate links with. Must be set with your hosted
  domain name! I.e. `cannery.mywebsite.tld`
- `PORT`: Internal port to bind to. Defaults to `4000`. Must be reverse proxied!
- `DATABASE_URL`: Controls the database url to connect to. Defaults to
  `ecto://postgres:postgres@cannery-db/cannery`.
- `ECTO_IPV6`: If set to `true`, Ecto should use ipv6 to connect to PostgreSQL.
  Defaults to `false`.
- `POOL_SIZE`: Controls the pool size to use with PostgreSQL. Defaults to `10`.
- `SECRET_KEY_BASE`: Secret key base used to sign cookies. Must be generated
  with `docker run -it shibaobun/cannery priv/random.sh` and set for server to start.
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
`postgres:13` to `pgautoupgrade/pgautoupgrade:17-alpine` and rerun
`docker-compose up -d`. This will automatically migrate your database to
Postgres 17, and then you can switch back to the original `postgres:17` image
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
[LICENSE.md](https://codeberg.org/shibao/cannery/src/branch/stable/LICENSE.md).

# Links

- [Website](https://cannery.app): Project website
- [Codeberg](https://codeberg.org/shibao/cannery): Main repo, feature
  requests and bug reports
- [Github](https://github.com/shibaobun/cannery): Source code mirror, please
  don't open pull requests to this repository
