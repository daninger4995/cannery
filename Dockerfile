FROM elixir:1.19.5-otp-28-alpine AS build

RUN apk add --no-cache build-base git nodejs npm python3

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config ./config
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY lib ./lib
COPY priv ./priv
COPY assets ./assets
RUN mix assets.deploy
RUN mix release

FROM alpine:3.22.1 AS app

RUN apk add --no-cache bash ca-certificates libgcc libstdc++ ncurses-libs openssl tzdata

WORKDIR /app

RUN addgroup -S cannery && adduser -S cannery -G cannery -h /app

ENV MIX_ENV=prod
ENV HOME=/app

COPY --from=build --chown=cannery:cannery /app/_build/prod/rel/cannery ./
COPY --from=build --chown=cannery:cannery /app/priv/random.sh ./priv/random.sh
RUN chmod +x /app/priv/random.sh

USER cannery:cannery

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
  CMD wget -q -O /dev/null http://127.0.0.1:${PORT:-4000}/ || exit 1

CMD ["bin/cannery", "start"]
