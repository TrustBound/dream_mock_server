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

/// Sends raw request text to the local server at `port`. Returns the
/// status line and the body of the answer, for example
/// `#("HTTP/1.1 404 Not Found", "Route not found")`, or the connection
/// error. The body is all the text after the empty line that ends the
/// headers, so send `connection: close` and expect a body that is not
/// chunked.
pub fn raw_status_and_body(
  port: Int,
  request: String,
) -> Result(#(String, String), String) {
  case raw_request(port, <<request:utf8>>) {
    Ok(answer) -> Ok(status_line_and_body(to_text(answer)))
    Error(reason) -> Error(to_text(reason))
  }
}

/// Sends raw request text to the local server at `port`. Returns every
/// byte of the answer as text, without the `date` header line, for example
/// `"HTTP/1.1 404 Not Found\r\n...\r\n\r\nRoute not found"`, or the
/// connection error. Send `connection: close` so that the server closes the
/// connection after the answer.
pub fn raw_answer(port: Int, request: String) -> Result(String, String) {
  case raw_request(port, <<request:utf8>>) {
    Ok(answer) -> Ok(without_date_line(to_text(answer)))
    Error(reason) -> Error(to_text(reason))
  }
}

/// How a connection was at the end of a `raw_exchange`.
pub type ConnectionEnding {
  /// The server closed the connection.
  ServerClosed
  /// The connection was still open after two seconds with no byte.
  StillOpen
}

/// What a client got on one connection in a `raw_exchange`. Each answer is
/// all the text that came, without its `date` header lines, and is `""`
/// when no byte came.
pub type Exchange {
  Exchange(first_answer: String, later_answer: String, ending: ConnectionEnding)
}

@external(erlang, "http_test_ffi", "raw_exchange")
fn raw_exchange_bytes(
  port: Int,
  first: BitArray,
  second: BitArray,
) -> Result(#(BitArray, BitArray, Bool), BitArray)

/// Sends `first` to the local server at `port` and reads what comes back
/// until the server closes the connection or sends nothing for half a
/// second. Then sends `second` on the same connection and reads again until
/// the server closes the connection or sends nothing for two seconds.
/// Returns the two answers and how the connection ended, or the connection
/// error.
pub fn raw_exchange(
  port: Int,
  first: String,
  second: String,
) -> Result(Exchange, String) {
  case raw_exchange_bytes(port, <<first:utf8>>, <<second:utf8>>) {
    Ok(#(first_answer, later_answer, closed)) ->
      Ok(Exchange(
        first_answer: without_date_line(to_text(first_answer)),
        later_answer: without_date_line(to_text(later_answer)),
        ending: connection_ending(closed),
      ))
    Error(reason) -> Error(to_text(reason))
  }
}

fn connection_ending(closed: Bool) -> ConnectionEnding {
  case closed {
    True -> ServerClosed
    False -> StillOpen
  }
}

fn without_date_line(text: String) -> String {
  string.split(text, "\r\n")
  |> list.filter(fn(line) { !string.starts_with(line, "date: ") })
  |> string.join("\r\n")
}

fn status_line_and_body(text: String) -> #(String, String) {
  let #(head, body) =
    string.split_once(text, "\r\n\r\n")
    |> result.unwrap(#(text, ""))
  #(first_line(head), body)
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
