//// Doc comment: compression.gzip_compress

import dream_mock_server/compression

/// The text `Hello, World!` as one gzip body.
pub fn gzip_body() -> BitArray {
  compression.gzip_compress(<<"Hello, World!":utf8>>)
}
