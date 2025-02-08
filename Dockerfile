FROM node:22-alpine AS node-and-signalcli-amd64

ENV SIGNAL_ACCOUNT='+1234567890'
ENV SIGNAL_GROUP='CHANGEME000JNJQa8KSXVL3DusF0VqRy000EXAMPLE='
ENV TELEGRAM_TOKEN='0123456789:CHANGEME000De4tctaETZ1D7x1CUEXAMPLE'
ENV TELEGRAM_GROUP='-123456789'

RUN apk add --no-cache dbus openjdk21-jre signal-cli &&\
    mkdir /telegram-signal-bridge && \
    chown -R 1000: /telegram-signal-bridge

WORKDIR /telegram-signal-bridge

USER 1000:1000

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
