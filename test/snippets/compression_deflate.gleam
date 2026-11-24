//// Doc comment: compression.deflate_compress

import dream_mock_server/compression

/// The text `Hello, World!` as one deflate body in the zlib format.
pub fn deflate_body() -> BitArray {
  compression.deflate_compress(<<"Hello, World!":utf8>>)
}
