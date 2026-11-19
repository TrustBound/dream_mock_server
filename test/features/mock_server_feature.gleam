//// Step definitions for `test/features/mock_server.feature`. Each scenario
//// starts the mock server on a free port in its Background step. The When
//// step sends the requests and then stops the server, so the Then steps
//// only check the responses and no server stays running.

import dream/servers/mist/server.{type ServerHandle} as dream_server
import dream_mock_server/server
import dream_test/gherkin/feature.{FeatureConfig, to_test_suite}
import dream_test/gherkin/parser
import dream_test/gherkin/steps.{type StepContext, get_int, get_string, get_word}
import dream_test/matchers.{
  be_at_least, be_equal, be_greater_than, be_ok, contain_string, or_fail_with,
  should, start_with,
}
import dream_test/types.{type TestSuite}
import fixtures/port
import fixtures/scenario_http
import gleam/bit_array
import gleam/http/response.{type Response}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

/// The state of one scenario: the port and handle of its server while the
/// server runs, and the responses of its When step.
pub type World {
  World(
    port: Int,
    server: Option(ServerHandle),
    responses: List(Response(BitArray)),
  )
}

// Given

fn step_server_running(world: World, _context: StepContext) {
  let port = port.free_port()
  use handle <- result.try(
    server.start(port) |> result.map_error(string.inspect),
  )
  Ok(World(..world, port: port, server: Some(handle)))
}

// When

fn step_send_request(world: World, context: StepContext) {
  use handle <- result.try(option.to_result(world.server, "No server runs"))
  let sent = {
    use method <- result.try(get_word(context.captures, 0))
    use path <- result.try(get_string(context.captures, 1))
    scenario_http.send(world.port, method, path)
  }
  dream_server.stop(handle)
  use response <- result.try(sent)
  Ok(World(..world, server: None, responses: [response]))
}

fn step_send_concurrent_requests(world: World, context: StepContext) {
  use handle <- result.try(option.to_result(world.server, "No server runs"))
  let sent = {
    use count <- result.try(get_int(context.captures, 0))
    use path <- result.try(get_string(context.captures, 1))
    scenario_http.send_concurrently(world.port, list.repeat(path, count))
  }
  dream_server.stop(handle)
  use responses <- result.try(sent)
  Ok(World(..world, server: None, responses: responses))
}

fn step_request_two_concurrently(world: World, context: StepContext) {
  use handle <- result.try(option.to_result(world.server, "No server runs"))
  let sent = {
    use first <- result.try(get_string(context.captures, 0))
    use second <- result.try(get_string(context.captures, 1))
    scenario_http.send_concurrently(world.port, [first, second])
  }
  dream_server.stop(handle)
  use responses <- result.try(sent)
  Ok(World(..world, server: None, responses: responses))
}

// Then: one response

fn step_status(world: World, context: StepContext) {
  use expected <- result.try(get_int(context.captures, 0))
  use response <- result.try(scenario_http.single(world.responses))
  response.status
  |> should
  |> be_equal(expected)
  |> or_fail_with("Wrong response status")
}

fn step_starts_with(world: World, context: StepContext) {
  use prefix <- result.try(get_string(context.captures, 0))
  use response <- result.try(scenario_http.single(world.responses))
  bit_array.to_string(response.body)
  |> should
  |> be_ok
  |> start_with(prefix)
  |> or_fail_with("The body does not start with " <> prefix)
}

fn step_contains(world: World, context: StepContext) {
  use text <- result.try(get_string(context.captures, 0))
  use response <- result.try(scenario_http.single(world.responses))
  bit_array.to_string(response.body)
  |> should
  |> be_ok
  |> contain_string(text)
  |> or_fail_with("The body does not contain " <> text)
}

fn step_valid_json(world: World, _context: StepContext) {
  use response <- result.try(scenario_http.single(world.responses))
  use invalid <- result.try(scenario_http.invalid_json_lines(response.body))
  invalid
  |> should
  |> be_equal([])
  |> or_fail_with("Every line of the body should be valid JSON")
}

fn step_header_contains(world: World, context: StepContext) {
  use name <- result.try(get_string(context.captures, 0))
  use text <- result.try(get_string(context.captures, 1))
  use response <- result.try(scenario_http.single(world.responses))
  response.get_header(response, string.lowercase(name))
  |> should
  |> be_ok
  |> contain_string(text)
  |> or_fail_with("The " <> name <> " header does not contain " <> text)
}

fn step_body_size_at_least(world: World, context: StepContext) {
  use minimum <- result.try(get_int(context.captures, 0))
  use response <- result.try(scenario_http.single(world.responses))
  bit_array.byte_size(response.body)
  |> should
  |> be_at_least(minimum)
  |> or_fail_with("The body is too small")
}

fn step_body_empty(world: World, _context: StepContext) {
  use response <- result.try(scenario_http.single(world.responses))
  response.body
  |> should
  |> be_equal(<<>>)
  |> or_fail_with("The body should be empty")
}

fn step_body_not_empty(world: World, _context: StepContext) {
  use response <- result.try(scenario_http.single(world.responses))
  bit_array.byte_size(response.body)
  |> should
  |> be_greater_than(0)
  |> or_fail_with("The body should not be empty")
}

fn step_line_count(world: World, context: StepContext) {
  use expected <- result.try(get_int(context.captures, 0))
  use response <- result.try(scenario_http.single(world.responses))
  use lines <- result.try(scenario_http.line_count(response.body))
  lines
  |> should
  |> be_equal(expected)
  |> or_fail_with("Wrong number of lines")
}

// Then: more than one response

fn step_all_statuses(world: World, context: StepContext) {
  use count <- result.try(get_int(context.captures, 0))
  use expected <- result.try(get_int(context.captures, 1))
  list.map(world.responses, fn(response) { response.status })
  |> should
  |> be_equal(list.repeat(expected, count))
  |> or_fail_with("Wrong response statuses")
}

fn step_all_line_counts(world: World, context: StepContext) {
  use count <- result.try(get_int(context.captures, 0))
  use expected <- result.try(get_int(context.captures, 1))
  use lines <- result.try(
    list.try_map(world.responses, fn(response) {
      scenario_http.line_count(response.body)
    }),
  )
  lines
  |> should
  |> be_equal(list.repeat(expected, count))
  |> or_fail_with("Wrong numbers of lines")
}

fn step_both_statuses(world: World, context: StepContext) {
  use expected <- result.try(get_int(context.captures, 0))
  list.map(world.responses, fn(response) { response.status })
  |> should
  |> be_equal([expected, expected])
  |> or_fail_with("Wrong response statuses")
}

fn step_first_line_count(world: World, context: StepContext) {
  use expected <- result.try(get_int(context.captures, 0))
  use response <- result.try(
    list.first(world.responses) |> result.replace_error("No first response"),
  )
  use lines <- result.try(scenario_http.line_count(response.body))
  lines
  |> should
  |> be_equal(expected)
  |> or_fail_with("Wrong number of lines")
}

fn step_second_line_count(world: World, context: StepContext) {
  use expected <- result.try(get_int(context.captures, 0))
  use response <- result.try(
    list.drop(world.responses, 1)
    |> list.first
    |> result.replace_error("No second response"),
  )
  use lines <- result.try(scenario_http.line_count(response.body))
  lines
  |> should
  |> be_equal(expected)
  |> or_fail_with("Wrong number of lines")
}

pub fn tests() -> TestSuite(Nil) {
  let steps =
    steps.new(initial: World(port: 0, server: None, responses: []))
    |> steps.given("the server is running on a free port", step_server_running)
    |> steps.when("I send a {word} request to {string}", step_send_request)
    |> steps.when(
      "I send {int} concurrent GET requests to {string}",
      step_send_concurrent_requests,
    )
    |> steps.when(
      "I concurrently request {string} and {string}",
      step_request_two_concurrently,
    )
    |> steps.then("the response status should be {int}", step_status)
    |> steps.then("the response should start with {string}", step_starts_with)
    |> steps.then("the response should contain {string}", step_contains)
    |> steps.then("the response should contain valid JSON", step_valid_json)
    |> steps.then(
      "the response header {string} should contain {string}",
      step_header_contains,
    )
    |> steps.then(
      "the response body size should be at least {int} bytes",
      step_body_size_at_least,
    )
    |> steps.then("the response body should be empty", step_body_empty)
    |> steps.then("the response body should not be empty", step_body_not_empty)
    |> steps.then(
      "the response should have exactly {int} lines",
      step_line_count,
    )
    |> steps.then(
      "all {int} responses should have status {int}",
      step_all_statuses,
    )
    |> steps.then(
      "all {int} responses should have exactly {int} lines",
      step_all_line_counts,
    )
    |> steps.then("both responses should have status {int}", step_both_statuses)
    |> steps.then(
      "the first response should have exactly {int} lines",
      step_first_line_count,
    )
    |> steps.then(
      "the second response should have exactly {int} lines",
      step_second_line_count,
    )

  let assert Ok(feature) =
    parser.parse_file("test/features/mock_server.feature")
  to_test_suite(FeatureConfig(feature: feature, step_registry: steps))
}
