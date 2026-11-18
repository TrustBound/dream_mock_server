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
@external(erlang, "compression_ffi", "deflate_compress_chunks")
pub fn deflate_compress_chunks(chunks: List(BitArray)) -> List(BitArray)
