//// Joins stream chunks into one bit array.

import dream_test/types.{type MatchResult, MatchFailed, MatchOk}
import gleam/bit_array

/// Joins the chunks of a stream, in order, into one bit array.
pub fn concatenate_chunks(
  result: MatchResult(List(BitArray)),
) -> MatchResult(BitArray) {
  case result {
    MatchFailed(failure) -> MatchFailed(failure)
    MatchOk(chunks) -> MatchOk(bit_array.concat(chunks))
  }
}
