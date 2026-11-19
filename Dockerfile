# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.12

# --- base: what every stage needs at runtime ---
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /app

ENV RACK_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y curl libpq5 \
    && rm -rf /var/lib/apt/lists/*

# --- build: compilers and headers to build native gems; discarded afterwards ---
FROM base AS build

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && rm -rf "${BUNDLE_PATH}"/ruby/*/cache

# --- final image: gems + app code, no build tools, no root ---
FROM base

RUN groupadd --system app && useradd --system --gid app --create-home app

COPY --from=build /usr/local/bundle /usr/local/bundle
# --chown makes the app user the owner of the code, so it can read it whatever
# permissions the files have on the machine that builds the image.
COPY --chown=app:app . .

USER app

EXPOSE 9292
CMD ["bundle", "exec", "puma"]
