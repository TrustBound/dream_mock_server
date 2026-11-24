//// Decompression for the tests of the compressed endpoints.

/// Decompresses one gzip stream.
@external(erlang, "zlib_test_ffi", "gunzip")
pub fn gunzip(data: BitArray) -> BitArray

/// Decompresses one zlib (deflate) stream.
@external(erlang, "zlib_test_ffi", "uncompress")
pub fn uncompress(data: BitArray) -> BitArray
