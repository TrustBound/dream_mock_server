//// HTTP requests and body checks for the Gherkin scenarios in
//// `test/features/`. The requests use `gleam_httpc`, so each response keeps
//// its headers and its body as bytes.

import gleam/bit_array
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string

/// Sends a request with `method` (for example "GET" or "POST") and an empty
/// body to `path` on the local server at `port`. Returns the response, or
/// the error as text.
pub fn send(
  port: Int,
  method: String,
  path: String,
) -> Result(Response(BitArray), String) {
  use method <- result.try(
    http.parse_method(method)
    |> result.replace_error("Unknown HTTP method: " <> method),
  )
  request.new()
  |> request.set_scheme(http.Http)
  |> request.set_host("localhost")
  |> request.set_port(port)
  |> request.set_path(path)
  |> request.set_method(method)
  |> request.set_body(<<>>)
  |> httpc.send_bits
  |> result.map_error(string.inspect)
}

/// Sends one GET request for each path in `paths`, each one from its own
/// process, so that the requests run at the same time. Returns the
/// responses in the order of `paths`, or the first error as text.
pub fn send_concurrently(
  port: Int,
  paths: List(String),
) -> Result(List(Response(BitArray)), String) {
  paths
  |> list.map(fn(path) {
    let reply = process.new_subject()
    process.spawn(fn() { process.send(reply, send(port, "GET", path)) })
    reply
  })
  |> list.try_map(fn(reply) {
    process.receive(reply, 35_000)
    |> result.replace_error("No response within 35 seconds")
    |> result.flatten
  })
}

/// Returns the one response of `responses`, or an error when there are
/// none or more than one.
pub fn single(
  responses: List(Response(BitArray)),
) -> Result(Response(BitArray), String) {
  case responses {
    [response] -> Ok(response)
    _other ->
      Error(
        "Expected one response, got " <> int.to_string(list.length(responses)),
      )
  }
}

/// Returns the number of lines of `body` that are not empty, or an error
/// when the body is not UTF-8 text.
pub fn line_count(body: BitArray) -> Result(Int, String) {
  use text <- result.map(body_text(body))
  text
  |> string.split("\n")
  |> list.filter(fn(line) { line != "" })
  |> list.length
}

/// Returns the lines of `body` that are not empty and are not valid JSON,
/// or an error when the body is not UTF-8 text.
pub fn invalid_json_lines(body: BitArray) -> Result(List(String), String) {
  use text <- result.map(body_text(body))
  text
  |> string.split("\n")
  |> list.filter(fn(line) {
    line != "" && result.is_error(json.parse(line, decode.dynamic))
  })
}

fn body_text(body: BitArray) -> Result(String, String) {
  bit_array.to_string(body)
  |> result.replace_error("The response body is not UTF-8 text")
}
