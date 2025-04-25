FROM elixir:1.17-slim as build

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy configuration files
COPY mix.exs mix.lock ./

# Install mix dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy application code
COPY lib lib

# Compile and build release
RUN mix compile
RUN mix release

# Prepare release image
FROM debian:12-slim

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app
COPY --from=build /app/_build/dev/rel/identiconner ./

# Create a non-root user and change ownership
RUN useradd -m appuser
RUN chown -R appuser: /app
USER appuser

# Set runtime environment
ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=4000

# Run the application
CMD ["bin/identiconner", "start"]

# Expose the port
EXPOSE 4000
