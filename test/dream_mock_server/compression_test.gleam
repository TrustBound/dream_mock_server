import dream_mock_server/compression
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/types.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/zlib
import gleam/bit_array
import gleam/list

pub fn tests() -> TestSuite(Nil) {
  describe("dream_mock_server/compression", [
    group("gzip_compress", [
      it("returns gzip data that gunzips to the input", fn() {
        // Act
        let compressed = compression.gzip_compress(<<"Hello, World!":utf8>>)

        // Assert
        zlib.gunzip(compressed)
        |> should
        |> be_equal(<<"Hello, World!":utf8>>)
        |> or_fail_with("Expected the input after gunzip")
      }),
    ]),
    group("deflate_compress", [
      it("returns zlib data that inflates to the input", fn() {
        // Act
        let compressed = compression.deflate_compress(<<"Hello, World!":utf8>>)

        // Assert
        zlib.uncompress(compressed)
        |> should
        |> be_equal(<<"Hello, World!":utf8>>)
        |> or_fail_with("Expected the input after inflate")
      }),
    ]),
    group("gzip_compress_chunks", [
      it("returns one chunk per input and one final chunk", fn() {
        // Act
        let chunks =
          compression.gzip_compress_chunks([<<"a":utf8>>, <<"b":utf8>>])

        // Assert
        list.length(chunks)
        |> should
        |> be_equal(3)
        |> or_fail_with("Expected three chunks")
      }),
      it("returns chunks that together gunzip to the joined input", fn() {
        // Act
        let chunks =
          compression.gzip_compress_chunks([<<"a":utf8>>, <<"b":utf8>>])

        // Assert
        zlib.gunzip(bit_array.concat(chunks))
        |> should
        |> be_equal(<<"ab":utf8>>)
        |> or_fail_with("Expected ab after gunzip")
      }),
    ]),
    group("deflate_compress_chunks", [
      it("returns one chunk per input and one final chunk", fn() {
        // Act
        let chunks =
          compression.deflate_compress_chunks([<<"a":utf8>>, <<"b":utf8>>])

        // Assert
        list.length(chunks)
        |> should
        |> be_equal(3)
        |> or_fail_with("Expected three chunks")
      }),
      it("returns chunks that together inflate to the joined input", fn() {
        // Act
        let chunks =
          compression.deflate_compress_chunks([<<"a":utf8>>, <<"b":utf8>>])

        // Assert
        zlib.uncompress(bit_array.concat(chunks))
        |> should
        |> be_equal(<<"ab":utf8>>)
        |> or_fail_with("Expected ab after inflate")
      }),
    ]),
  ])
}
