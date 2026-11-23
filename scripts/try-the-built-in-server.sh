#!/bin/sh
# The requests of Step 2 of the guide "Run the server while you develop"
# (docs/guides/run-the-server.md), for the server of "make run". The test
# guides/run_the_server_test starts a server on port 3004, runs this script,
# and compares what it prints with
# test/outputs/guide_run_the_server_built_in.txt.
set -eu

curl -i -w '\n' http://localhost:3004/json
curl -w '\n' "http://localhost:3004/get?page=2"
curl -w '\n' -X POST -d 'hello' http://localhost:3004/post
curl -N http://localhost:3004/stream/slow
