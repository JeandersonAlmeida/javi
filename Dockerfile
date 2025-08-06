ARG ELIXIR_VERSION=1.18.0
ARG OTP_VERSION=26.2.5.5
ARG DEBIAN_VERSION=bullseye-20241202-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:bullseye-slim"

FROM ${BUILDER_IMAGE} AS builder

# Install build deps
RUN apt-get update -y && apt-get install -y build-essential git curl gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update -y && apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Hex & Rebar
RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mkdir config

COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN npm install --prefix assets
RUN mix assets.deploy
RUN mix compile

COPY config/runtime.exs config/

RUN mix release

FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
WORKDIR "/app"
RUN chown nobody /app

ENV MIX_ENV=prod

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/javi ./

USER nobody

CMD ["/app/bin/javi", "start"]
