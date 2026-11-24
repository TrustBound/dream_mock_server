#!/usr/bin/env bash
# Runs each command of the guide "Run the server while you develop"
# (docs/guides/run-the-server.md) that serves until you stop it. For each
# one, the script waits until it prints that it listens, and then stops it
# with all its processes. It sends no request: the tests of the guide send
# the requests to servers that they start themselves. "make smoke" and
# scripts/check.sh run this script.
set -eu

log=build/run-server-smoke.log
group=""

# Stops the processes of the command that runs, and waits until they end.
stop_command() {
  if [ -n "$group" ]; then
    disown "$group" 2>/dev/null || true
    kill -TERM -- "-$group" 2>/dev/null || true
    while kill -0 -- "-$group" 2>/dev/null; do
      sleep 0.1
    done
    group=""
  fi
}
trap stop_command EXIT

# Waits up to 2 minutes until the log of the command holds the text $1,
# and then stops the command.
wait_for() {
  tries=0
  until grep -qF "$1" "$log"; do
    if ! kill -0 -- "-$group" 2>/dev/null || [ "$tries" -ge 1200 ]; then
      echo "The command did not print: $1" >&2
      cat "$log" >&2
      exit 1
    fi
    tries=$((tries + 1))
    sleep 0.1
  done
  stop_command
}

# Each command runs in its own process group, so that the script can stop
# make, gleam and the Erlang VM together.
set -m

# Step 1: the built-in server on port 3004.
(
make run
) > "$log" 2>&1 &
group=$!
wait_for "Listening on http://127.0.0.1:3004"

# The usage of the module standalone: the same server, with no make.
(
gleam run -m standalone
) > "$log" 2>&1 &
group=$!
wait_for "Listening on http://127.0.0.1:3004"

# Step 3: the chat API stand-in on port 4010.
(
gleam run -m dev_chat_api
) > "$log" 2>&1 &
group=$!
wait_for "Chat API stand-in on http://localhost:4010"

echo "Each server of the guide started and stopped."
