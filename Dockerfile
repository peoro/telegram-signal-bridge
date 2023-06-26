# Versions are only used in arm64 build
ARG LIBSIGNAL_VERSION='0.25.0'
ARG SIGNALCLI_VERSION='0.11.11'

##### ARM64 STAGE 1 #####
# Build libsignal library with rust beta if target is arm64 (aarch64).
# It is needed since there's no aarch64 version of the alpine package (because of Rust beta toolchain requirement)
# See alpine aports issue #15038 : https://gitlab.alpinelinux.org/alpine/aports/-/issues/15038
FROM --platform=linux/arm64 alpine:3.18 as libsignal-build-arm64

ARG LIBSIGNAL_VERSION
ARG SIGNALCLI_VERSION
# Fix memory usage by using git cli, see https://github.com/tonistiigi/binfmt/issues/122#issuecomment-1359175441
ARG CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN apk add curl openjdk17-jdk gradle protoc build-base cmake clang-dev git && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup-init.sh && \
    sh rustup-init.sh --default-toolchain beta -q -y

RUN source "$HOME/.cargo/env" && \
    wget "https://github.com/signalapp/libsignal/archive/refs/tags/v${LIBSIGNAL_VERSION}.tar.gz" && \
    tar -xf "v${LIBSIGNAL_VERSION}.tar.gz" && \
    cd "libsignal-${LIBSIGNAL_VERSION}/java/" && \
    sed -i "s/include ':android'//" settings.gradle && \
    export RUSTFLAGS="-C target-feature=-crt-static" && \
    sh ./build_jni.sh desktop


##### ARM64 STAGE 2 #####
# Prepare base layer for arm64 version (use github release for signal-cli and replace libsignal with ours)
FROM node:18-alpine as node-and-signalcli-arm64

ARG LIBSIGNAL_VERSION
ARG SIGNALCLI_VERSION

COPY --from=libsignal-build-arm64 /libsignal-${LIBSIGNAL_VERSION}/target/release/libsignal_jni.so .

RUN apk add --no-cache zip && \
    wget "https://github.com/AsamK/signal-cli/releases/download/v${SIGNALCLI_VERSION}/signal-cli-${SIGNALCLI_VERSION}-Linux.tar.gz" && \
    tar -xf "signal-cli-${SIGNALCLI_VERSION}-Linux.tar.gz" -C /opt && \
    ln -sf "/opt/signal-cli-"${SIGNALCLI_VERSION}"/bin/signal-cli" /usr/local/bin/ && \
    zip -d "/opt/signal-cli-${SIGNALCLI_VERSION}/lib/libsignal-client-${LIBSIGNAL_VERSION}.jar" libsignal_jni.so && \
    zip "/opt/signal-cli-${SIGNALCLI_VERSION}/lib/libsignal-client-${LIBSIGNAL_VERSION}.jar" libsignal_jni.so && \
    rm -rf libsignal_jni.so signal-cli-"${SIGNALCLI_VERSION}"-Linux.tar.gz && \
    apk del zip

RUN apk add --no-cache dbus openjdk17-jre


##### AMD64 STAGE 1 #####
# Prepare base layer for amd64 version (use alpine packages signal-cli and libsignal-client)
FROM node:18-alpine as node-and-signalcli-amd64

RUN apk add --no-cache dbus openjdk17-jre && \
    apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing/ signal-cli


##### ARM64/AMD64 FINAL STAGE #####
FROM node-and-signalcli-${TARGETARCH}

ENV SIGNAL_ACCOUNT='+1234567890'
ENV SIGNAL_GROUP='CHANGEME000JNJQa8KSXVL3DusF0VqRy000EXAMPLE='
ENV TELEGRAM_TOKEN='0123456789:CHANGEME000De4tctaETZ1D7x1CUEXAMPLE'
ENV TELEGRAM_GROUP='-123456789'

RUN mkdir /telegram-signal-bridge && \
    chown -R 1000: /telegram-signal-bridge

WORKDIR /telegram-signal-bridge

USER 1000:1000

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
