#!/bin/sh
# What CI checks: the format, the build, the tests with coverage, the docs
# code blocks, the docs build, and the servers of the guide "Run the server
# while you develop". "make check" runs this script.
set -eu

gleam format --check src test
gleam build
gleam test
gleam run -m dream_snippets
gleam docs build
bash scripts/run-server-smoke.sh
