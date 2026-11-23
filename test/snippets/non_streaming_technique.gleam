//// README: Non-Streaming Technique

import gleam/json

/// The JSON body of an echo answer: the method and the path of the request
/// in one object, for example `{"method":"DELETE","url":"/delete"}`.
pub fn echo_body(method: String, path: String) -> String {
  json.object([
    #("method", json.string(method)),
    #("url", json.string(path)),
  ])
  |> json.to_string
}
