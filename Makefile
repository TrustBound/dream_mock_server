.PHONY: run test build format check check-snippets smoke docs clean

# Runs the mock server on http://localhost:3004 until you stop it.
run:
	@gleam run -m standalone

# Runs every test and checks that the line coverage of src/ is 100%.
test:
	@gleam test

build:
	@gleam build

format:
	@gleam format src test

# What CI checks: format, build, tests with coverage, the docs code blocks,
# the docs build, and the servers of the guides.
check:
	@sh scripts/check.sh

# Checks that each code block in the docs matches a tested snippet file.
check-snippets:
	@gleam run -m dream_snippets

# Starts and stops each server that the guide "Run the server while you
# develop" runs until you stop it.
smoke:
	@bash scripts/run-server-smoke.sh

docs:
	@gleam docs build

clean:
	@gleam clean
