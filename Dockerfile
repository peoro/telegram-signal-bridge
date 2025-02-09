# Choose base to build image (with or without cloning code). Available values: ['prod', 'dev']:
ARG BUILD_ENV=prod

##### STAGE 1 - BASE #####
# Install common dependencies
FROM node:22-alpine AS base_common
RUN apk add --no-cache dbus openjdk21-jre signal-cli


##### STAGE 2a - PROD #####
# Prod variant, download and setup telegram-signal-bridge
FROM base_common AS base_telegram-signal-bridge_prod

ARG GIT_REPO='https://github.com/peoro/telegram-signal-bridge'
# You can specify a branch instead of a tag but a tag is prefered (full ref like 'refs/heads/<branch>' works too)
ARG GIT_TAG='main'

ONBUILD RUN mkdir /telegram-signal-bridge && chown -R 1000: /telegram-signal-bridge && cd /telegram-signal-bridge &&\
            apk add --no-cache curl && apk add --no-cache gosu --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing &&\
            # Step down from root to non-privileged "node" user (id 1000) to download repository and install npm packages
            gosu 1000 sh -c "{ curl -L ${GIT_REPO}/archive/${GIT_TAG}.tar.gz | tar -xzv --strip 1; } && npm ci"


##### STAGE 2b - DEV #####
# Dev variant, we won't need the codebase since we will bindmount it, only prepare the folder
FROM base_common AS base_telegram-signal-bridge_dev
ONBUILD RUN mkdir /telegram-signal-bridge && chown -R 1000: /telegram-signal-bridge


##### STAGE 3 - FINAL #####
FROM base_telegram-signal-bridge_${BUILD_ENV}

WORKDIR /telegram-signal-bridge

USER 1000:1000

VOLUME /home/node/.local/share/signal-cli

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
