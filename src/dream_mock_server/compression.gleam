//// Compression for the compressed endpoints, with the zlib library of
//// Erlang.
////
//// The streaming functions compress a list of chunks as one stream, so the
//// chunks can be sent one by one and decompressed one by one.

/// Compresses data with gzip, in one piece.
///
/// ## Parameters
///
/// - `data`: The bytes to compress.
///
/// ## Returns
///
/// The gzip bytes, with the gzip header and trailer.
///
/// ## Example
///
/// ### Compress a body with gzip <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/compression_gzip.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/compression
///
/// /// The text `Hello, World!` as one gzip body.
/// pub fn gzip_body() -> BitArray {
///   compression.gzip_compress(<<"Hello, World!":utf8>>)
/// }
/// ```
@external(erlang, "compression_ffi", "gzip_compress")
pub fn gzip_compress(data: BitArray) -> BitArray

/// Compresses data with deflate in the zlib format, in one piece.
///
/// ## Parameters
///
/// - `data`: The bytes to compress.
///
/// ## Returns
///
/// The zlib bytes, which is the format of `Content-Encoding: deflate`.
///
/// ## Example
///
/// ### Compress a body with deflate <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/compression_deflate.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/compression
///
/// /// The text `Hello, World!` as one deflate body in the zlib format.
/// pub fn deflate_body() -> BitArray {
///   compression.deflate_compress(<<"Hello, World!":utf8>>)
/// }
/// ```
@external(erlang, "compression_ffi", "deflate_compress")
pub fn deflate_compress(data: BitArray) -> BitArray

/// Compresses a list of chunks as one gzip stream.
///
/// Each input chunk is flushed, so each output chunk can be decompressed as
/// soon as it arrives.
///
/// ## Parameters
///
/// - `chunks`: The bytes to compress, in order.
///
/// ## Returns
///
/// One compressed chunk for each input chunk, then one last chunk that ends
/// the stream. Joined in order, the chunks are one valid gzip stream.
///
/// ## Example
///
/// ### Compress two chunks as one gzip stream <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/compression_gzip_chunks.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/compression
///
/// /// Two text chunks as one gzip stream: three compressed chunks, one for each
/// /// text chunk and one that ends the stream.
/// pub fn gzip_stream_chunks() -> List(BitArray) {
///   compression.gzip_compress_chunks([<<"Chunk 1\n":utf8>>, <<"Chunk 2\n":utf8>>])
/// }
/// ```
@external(erlang, "compression_ffi", "gzip_compress_chunks")
pub fn gzip_compress_chunks(chunks: List(BitArray)) -> List(BitArray)

/// Compresses a list of chunks as one deflate stream in the zlib format.
///
/// Each input chunk is flushed, so each output chunk can be decompressed as
/// soon as it arrives.
///
/// ## Parameters
///
/// - `chunks`: The bytes to compress, in order.
///
/// ## Returns
///
/// One compressed chunk for each input chunk, then one last chunk that ends
/// the stream. Joined in order, the chunks are one valid zlib stream.
///
/// ## Example
///
/// ### Compress two chunks as one deflate stream <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/compression_deflate_chunks.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>
///
/// ```gleam
/// import dream_mock_server/compression
///
/// /// Two text chunks as one deflate stream: three compressed chunks, one for
/// /// each text chunk and one that ends the stream.
/// pub fn deflate_stream_chunks() -> List(BitArray) {
///   compression.deflate_compress_chunks([
///     <<"Chunk 1\n":utf8>>,
///     <<"Chunk 2\n":utf8>>,
///   ])
/// }
/// ```
@external(erlang, "compression_ffi", "deflate_compress_chunks")
pub fn deflate_compress_chunks(chunks: List(BitArray)) -> List(BitArray)
