//// Guide: Getting started, step 1
////
//// A small client function that takes the base URL of the service it calls.

import gleam/http/request
import gleam/httpc
import gleam/result
import gleam/string

pub type GreetingError {
  /// The URL is not valid.
  BadUrl(url: String)
  /// The request did not get a response.
  RequestFailed(reason: String)
  /// The server answered with a status other than 200.
  UnexpectedStatus(status: Int)
}

/// Fetches the greeting at `<base_url>/text`. Your program passes the URL
/// of the real service, and your tests pass the URL of the mock server.
pub fn fetch_greeting(base_url: String) -> Result(String, GreetingError) {
  let url = base_url <> "/text"
  use http_request <- result.try(
    request.to(url) |> result.replace_error(BadUrl(url)),
  )
  use response <- result.try(
    httpc.send(http_request)
    |> result.map_error(fn(error) { RequestFailed(string.inspect(error)) }),
  )
  case response.status {
    200 -> Ok(response.body)
    status -> Error(UnexpectedStatus(status))
  }
}
