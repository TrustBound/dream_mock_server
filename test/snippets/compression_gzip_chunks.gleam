//// Doc comment: compression.gzip_compress_chunks

import dream_mock_server/compression

/// Two text chunks as one gzip stream: three compressed chunks, one for each
/// text chunk and one that ends the stream.
pub fn gzip_stream_chunks() -> List(BitArray) {
  compression.gzip_compress_chunks([<<"Chunk 1\n":utf8>>, <<"Chunk 2\n":utf8>>])
}
