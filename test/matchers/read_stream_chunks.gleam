//// Reads every chunk of a streamed response body.

import dream_mock_server/internal/message.{type Body, type Response, Stream}
import dream_test/types.{
  type MatchResult, AssertionFailure, CustomMatcherFailure, MatchFailed, MatchOk,
}
import gleam/option.{Some}
import gleam/yielder

/// Reads the whole `Stream` body of a response and gives its chunks in
/// order. Fails when the body is not a `Stream`.
pub fn read_stream_chunks(
  result: MatchResult(Response),
) -> MatchResult(List(BitArray)) {
  case result {
    MatchFailed(failure) -> MatchFailed(failure)
    MatchOk(response) -> read_body(response.body)
  }
}

fn read_body(body: Body) -> MatchResult(List(BitArray)) {
  case body {
    Stream(chunks) -> MatchOk(yielder.to_list(chunks))
    _not_a_stream -> not_a_stream_failure()
  }
}

fn not_a_stream_failure() -> MatchResult(List(BitArray)) {
  MatchFailed(AssertionFailure(
    operator: "read_stream_chunks",
    message: "Expected a Stream body",
    payload: Some(CustomMatcherFailure(
      actual: "Body that is not a Stream",
      description: "Body is not a Stream",
    )),
  ))
}
