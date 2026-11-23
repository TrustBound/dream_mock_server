.PHONY: run test build format check check-snippets docs clean

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

# What CI checks: format, build, tests with coverage, the docs build, and
# the docs code blocks against the tested snippets.
check:
	@gleam format --check src test
	@gleam build
	@gleam test
	@gleam docs build
	@gleam run -m dream_snippets

# Checks that each code block in the docs matches a tested snippet file.
check-snippets:
	@gleam run -m dream_snippets

docs:
	@gleam docs build

clean:
	@gleam clean
