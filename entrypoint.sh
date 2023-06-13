#!/bin/sh
set -e

exec dbus-run-session -- sh -c \
"signal-cli -a ${SIGNAL_ACCOUNT} daemon&
echo 'Waiting for 5s for signal-cli to start' && sleep 5 && npm run start"
