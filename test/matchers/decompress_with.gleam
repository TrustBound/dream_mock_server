//// Decompresses a bit array for the next matcher.

import dream_test/types.{type MatchResult, MatchFailed, MatchOk}

/// Gives the result of `decompress` on the value, for example
/// `fixtures/zlib.gunzip`.
pub fn decompress_with(
  result: MatchResult(BitArray),
  decompress: fn(BitArray) -> BitArray,
) -> MatchResult(BitArray) {
  case result {
    MatchFailed(failure) -> MatchFailed(failure)
    MatchOk(data) -> MatchOk(decompress(data))
  }
}
