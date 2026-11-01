#!/bin/sh
# Runs the greeter as a normal window with the mock backend
# (password "test"). State goes to /tmp so nothing real is touched.
cd "$(dirname "$0")" || exit 1
QD_GREETER_MOCK=1 QD_GREETER_STATE=/tmp/qd-greeter-state.json \
    exec qs -p "$PWD" -n "$@"
