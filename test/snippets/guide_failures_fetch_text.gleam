//// Guide: Test how your client handles failures, step 1
////
//// A client function that turns each kind of failure into its own error.

import gleam/bit_array
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/result

pub type FetchError {
  /// The URL is not valid.
  BadUrl(url: String)
  /// Nothing accepts connections at the address.
  Unreachable
  /// The whole response did not arrive within the timeout.
  TimedOut
  /// The server answered with a status outside 2xx.
  Refused(status: Int, body: BitArray)
  /// The body has a content encoding that this code cannot read.
  UnsupportedEncoding(encoding: String)
  /// The body of a 2xx response is not UTF-8 text.
  NotText(body: BitArray)
}

/// Gets the text at `url`, and waits at most `timeout_ms` for the whole
/// response.
pub fn fetch_text(url: String, timeout_ms: Int) -> Result(String, FetchError) {
  use http_request <- result.try(
    request.to(url) |> result.replace_error(BadUrl(url)),
  )
  use response <- result.try(
    httpc.configure()
    |> httpc.timeout(timeout_ms)
    |> httpc.dispatch_bits(request.set_body(http_request, <<>>))
    |> result.map_error(describe_error),
  )
  use body <- result.try(check_status(response))
  use body <- result.try(check_encoding(response, body))
  bit_array.to_string(body) |> result.replace_error(NotText(body))
}

fn describe_error(error: httpc.HttpError) -> FetchError {
  case error {
    httpc.FailedToConnect(..) -> Unreachable
    httpc.ResponseTimeout -> TimedOut
    // Only `httpc.dispatch` checks for UTF-8. `dispatch_bits` never does.
    httpc.InvalidUtf8Response -> NotText(<<>>)
  }
}

fn check_status(response: Response(BitArray)) -> Result(BitArray, FetchError) {
  case response.status >= 200 && response.status < 300 {
    True -> Ok(response.body)
    False -> Error(Refused(status: response.status, body: response.body))
  }
}

fn check_encoding(
  response: Response(BitArray),
  body: BitArray,
) -> Result(BitArray, FetchError) {
  case response.get_header(response, "content-encoding") {
    Error(Nil) | Ok("identity") -> Ok(body)
    Ok(encoding) -> Error(UnsupportedEncoding(encoding))
  }
}
