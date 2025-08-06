# --- Build Stage ---
  ARG ELIXIR_VERSION=1.18.0
  ARG OTP_VERSION=26.0
  ARG DEBIAN_VERSION=bullseye-20240227-slim
  
  ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
  ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"
  
  FROM ${BUILDER_IMAGE} as builder
  
  # Install build dependencies
  RUN apt-get update -y && \
      apt-get install -y build-essential git curl gnupg && \
      apt-get clean && rm -rf /var/lib/apt/lists/*
  
  # --- Install Node.js 20.x ---
  RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
      apt-get update -y && \
      apt-get install -y nodejs && \
      apt-get clean && rm -rf /var/lib/apt/lists/*
  
  # Set app working directory
  WORKDIR /app
  
  # Install Hex and Rebar
  RUN mix local.hex --force && \
      mix local.rebar --force
  
  # Set environment
  ENV MIX_ENV=prod
  
  # Copy and install mix dependencies
  COPY mix.exs mix.lock ./
  RUN mix deps.get --only prod
  RUN mkdir config
  
  # Copy configs before compiling dependencies to avoid stale builds
  COPY config/config.exs config/prod.exs config/
  RUN mix deps.compile
  
  # Copy application code
  COPY priv priv
  COPY lib lib
  COPY assets assets
  
  # Install npm dependencies (for JS/CSS assets)
  RUN npm install --prefix assets
  
  # Build frontend assets
  RUN mix assets.deploy
  
  # Compile Elixir project
  RUN mix compile
  
  # Copy runtime config and release definitions
  COPY config/runtime.exs config/
  COPY rel rel
  
  # Generate the release
  RUN mix release
  
  # --- Runtime Stage ---
  FROM ${RUNNER_IMAGE}
  
  # Install minimal runtime dependencies
  RUN apt-get update -y && \
      apt-get install -y libstdc++6 openssl libncurses5 locales && \
      apt-get clean && rm -rf /var/lib/apt/lists/*
  
  # Generate system locale
  RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
  
  ENV LANG en_US.UTF-8
  ENV LANGUAGE en_US:en
  ENV LC_ALL en_US.UTF-8
  
  # Set working directory and permissions
  WORKDIR "/app"
  RUN chown nobody /app
  
  # Set environment
  ENV MIX_ENV=prod
  
  # Copy only the final release from the build stage
  COPY --from=builder --chown=nobody:root /app/_build/prod/rel/javi ./
  
  # Run as non-root user
  USER nobody
  
  # Start the Phoenix application release
  CMD ["/app/bin/javi", "start"]
  