//// Guide: Test how your client handles failures, step 5
////
//// The exact bytes that GET /stream/gzip sends, joined in order.

import dream_mock_server/compression
import gleam/bit_array

/// The body of `GET /stream/gzip`: the lines `Chunk 1` to `Chunk 5` as one
/// gzip stream.
pub fn expected_gzip_stream() -> BitArray {
  compression.gzip_compress_chunks([
    <<"Chunk 1\n":utf8>>,
    <<"Chunk 2\n":utf8>>,
    <<"Chunk 3\n":utf8>>,
    <<"Chunk 4\n":utf8>>,
    <<"Chunk 5\n":utf8>>,
  ])
  |> bit_array.concat
}
