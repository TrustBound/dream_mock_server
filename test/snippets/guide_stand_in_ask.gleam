//// Guide: Stand in for a third-party API, step 1
////
//// A client for a chat completion API that takes the base URL of the API.

import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import gleam/string

pub type ChatError {
  /// The URL is not valid.
  BadUrl(url: String)
  /// The request did not get a response.
  RequestFailed(reason: String)
  /// The API answered with status 429: too many requests.
  RateLimited
  /// The API answered with another status that is not 200.
  ApiError(status: Int, body: String)
  /// The API answered 200, but the body is not the JSON this code expects.
  BadReply(body: String)
}

/// Sends one question to the chat completion API at `base_url` and returns
/// the text of the first answer.
pub fn ask(
  base_url: String,
  api_key: String,
  question: String,
) -> Result(String, ChatError) {
  let url = base_url <> "/v1/chat/completions"
  use http_request <- result.try(
    request.to(url) |> result.replace_error(BadUrl(url)),
  )
  let http_request =
    http_request
    |> request.set_method(http.Post)
    |> request.set_header("authorization", "Bearer " <> api_key)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(question_json(question))
  use response <- result.try(
    httpc.send(http_request)
    |> result.map_error(fn(error) { RequestFailed(string.inspect(error)) }),
  )
  case response.status {
    200 -> first_answer(response.body)
    429 -> Error(RateLimited)
    status -> Error(ApiError(status: status, body: response.body))
  }
}

fn question_json(question: String) -> String {
  json.object([
    #("model", json.string("example-model")),
    #(
      "messages",
      json.preprocessed_array([
        json.object([
          #("role", json.string("user")),
          #("content", json.string(question)),
        ]),
      ]),
    ),
  ])
  |> json.to_string
}

fn first_answer(body: String) -> Result(String, ChatError) {
  let answers_decoder =
    decode.at(
      ["choices"],
      decode.list(decode.at(["message", "content"], decode.string)),
    )
  case json.parse(body, answers_decoder) {
    Ok([answer, ..]) -> Ok(answer)
    Ok([]) | Error(_) -> Error(BadReply(body))
  }
}
