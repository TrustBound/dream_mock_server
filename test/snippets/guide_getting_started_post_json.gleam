//// Guide: Getting started, step 4
////
//// Sends a JSON body with a POST request, to check against the echo
//// endpoints.

import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json.{type Json}
import gleam/result
import gleam/string

/// Sends `body` as JSON to `url` with a POST request. Returns the status and
/// the body of the response.
pub fn post_json(url: String, body: Json) -> Result(#(Int, String), String) {
  use http_request <- result.try(
    request.to(url) |> result.replace_error("Not a valid URL: " <> url),
  )
  let http_request =
    http_request
    |> request.set_method(http.Post)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json.to_string(body))
  use response <- result.try(
    httpc.send(http_request) |> result.map_error(string.inspect),
  )
  Ok(#(response.status, response.body))
}

/// The JSON of a new note.
pub fn note_json(text: String) -> Json {
  json.object([#("text", json.string(text))])
}
