//// Guide: Stand in for a third-party API, steps 2 and 3
////
//// The routes of a chat completion API stand-in: one answer, and two ways
//// to fail.

import dream_mock_server/config.{type MockRoute, Exact, MockRoute}
import gleam/http.{Post}
import gleam/option.{Some}

/// A chat completion API that answers every question with the same text.
pub fn chat_routes() -> List(MockRoute) {
  [
    MockRoute(
      path: "/v1/chat/completions",
      path_match: Exact,
      method: Some(Post),
      status: 200,
      body: "{\"id\":\"chatcmpl-1\",\"object\":\"chat.completion\","
        <> "\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\","
        <> "\"content\":\"Hello from the stand-in.\"},\"finish_reason\":\"stop\"}]}",
    ),
  ]
}

/// A chat completion API that refuses every question: too many requests.
pub fn rate_limited_routes() -> List(MockRoute) {
  [
    MockRoute(
      path: "/v1/chat/completions",
      path_match: Exact,
      method: Some(Post),
      status: 429,
      body: "{\"error\":{\"message\":\"Rate limit reached\"}}",
    ),
  ]
}

/// A chat completion API that answers 200 with a body that is not JSON.
pub fn broken_routes() -> List(MockRoute) {
  [
    MockRoute(
      path: "/v1/chat/completions",
      path_match: Exact,
      method: Some(Post),
      status: 200,
      body: "upstream connect error",
    ),
  ]
}
