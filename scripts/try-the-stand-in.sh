#!/bin/sh
# The request of Step 3 of the guide "Run the server while you develop"
# (docs/guides/run-the-server.md), for the stand-in on port 4010. The test
# guides/run_the_server_test starts the stand-in, runs this script, and
# compares what it prints with test/outputs/guide_run_the_server_stand_in.txt.
set -eu

curl -w '\n' -X POST http://localhost:4010/v1/chat/completions
