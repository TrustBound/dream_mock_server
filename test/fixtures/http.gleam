//// HTTP requests to a running mock server, for the server tests.

import gleam/bit_array
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/result
import gleam/string

@external(erlang, "http_test_ffi", "make_request_full")
fn make_request_full(url: String) -> Result(#(Int, BitArray), BitArray)

@external(erlang, "http_test_ffi", "make_request_with_method")
fn make_request_with_method(
  url: String,
  method: String,
  body: String,
) -> Result(#(Int, BitArray), BitArray)

@external(erlang, "http_test_ffi", "raw_request")
fn raw_request(port: Int, request: BitArray) -> Result(BitArray, BitArray)

/// Sends raw request text to the local server at `port`. Returns the
/// status line of the answer, for example `HTTP/1.1 404 Not Found`, or the
/// connection error.
pub fn raw_status_line(port: Int, request: String) -> Result(String, String) {
  case raw_request(port, <<request:utf8>>) {
    Ok(answer) -> Ok(first_line(to_text(answer)))
    Error(reason) -> Error(to_text(reason))
  }
}

fn first_line(text: String) -> String {
  string.split(text, "\r\n")
  |> list.first
  |> result.unwrap("")
}

/// Returns the URL of `path` on the local server at `port`.
pub fn url(port: Int, path: String) -> String {
  "http://localhost:" <> int.to_string(port) <> path
}

/// Sends a GET request. Returns the status and the body text, or the
/// connection error.
pub fn get(url: String) -> Result(#(Int, String), String) {
  make_request_full(url)
  |> to_status_and_text
}

/// Sends a request with `method` ("GET", "POST", "PUT", "DELETE" or
/// "PATCH") and `body`. Returns the status and the body text, or the
/// connection error.
pub fn send(
  method: String,
  url: String,
  body: String,
) -> Result(#(Int, String), String) {
  make_request_with_method(url, method, body)
  |> to_status_and_text
}

/// Sends GET requests until the server answers, at most `attempts` times
/// with 50 ms between them. Returns the last result.
pub fn get_when_ready(
  url: String,
  attempts: Int,
) -> Result(#(Int, String), String) {
  case get(url), attempts > 1 {
    Error(_not_ready), True -> {
      process.sleep(50)
      get_when_ready(url, attempts - 1)
    }
    response, _last_attempt -> response
  }
}

fn to_status_and_text(
  response: Result(#(Int, BitArray), BitArray),
) -> Result(#(Int, String), String) {
  case response {
    Ok(#(status, body)) -> Ok(#(status, to_text(body)))
    Error(reason) -> Error(to_text(reason))
  }
}

fn to_text(bits: BitArray) -> String {
  bit_array.to_string(bits)
  |> result.unwrap("<not UTF-8>")
}
