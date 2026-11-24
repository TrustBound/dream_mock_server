//// Reads the first chunks of a streamed response body.

import dream_mock_server/internal/message.{type Body, type Response, Stream}
import dream_test/types.{
  type MatchResult, AssertionFailure, CustomMatcherFailure, MatchFailed, MatchOk,
}
import gleam/option.{Some}
import gleam/yielder

/// Reads only the first `count` chunks of the `Stream` body of a response.
/// Use it for a stream that fails after its first chunks. Fails when the
/// body is not a `Stream`.
pub fn take_stream_chunks(
  result: MatchResult(Response),
  count: Int,
) -> MatchResult(List(BitArray)) {
  case result {
    MatchFailed(failure) -> MatchFailed(failure)
    MatchOk(response) -> take_from_body(response.body, count)
  }
}

fn take_from_body(body: Body, count: Int) -> MatchResult(List(BitArray)) {
  case body {
    Stream(chunks) -> MatchOk(chunks |> yielder.take(count) |> yielder.to_list)
    _not_a_stream -> not_a_stream_failure()
  }
}

fn not_a_stream_failure() -> MatchResult(List(BitArray)) {
  MatchFailed(AssertionFailure(
    operator: "take_stream_chunks",
    message: "Expected a Stream body",
    payload: Some(CustomMatcherFailure(
      actual: "Body that is not a Stream",
      description: "Body is not a Stream",
    )),
  ))
}
