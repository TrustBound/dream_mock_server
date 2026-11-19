.PHONY: run test build format check docs clean

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

# What CI checks: format, build, tests with coverage, and the docs build.
check:
	@gleam format --check src test
	@gleam build
	@gleam test
	@gleam docs build

docs:
	@gleam docs build

clean:
	@gleam clean
