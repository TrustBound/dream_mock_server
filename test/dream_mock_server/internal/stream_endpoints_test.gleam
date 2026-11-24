import dream_mock_server/internal/stream_endpoints
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/request as test_request
import fixtures/stream_chunks.{binary_chunks, huge_chunks}
import fixtures/zlib
import gleam/http.{Get}
import matchers/concatenate_chunks.{concatenate_chunks}
import matchers/decompress_with.{decompress_with}
import matchers/read_stream_chunks.{read_stream_chunks}
import matchers/take_stream_chunks.{take_stream_chunks}

pub fn tests() -> TestSuite {
  describe("dream_mock_server/internal/stream_endpoints", [
    stream_fast_tests(),
    stream_slow_tests(),
    stream_burst_tests(),
    stream_error_tests(),
    stream_drop_tests(),
    stream_huge_tests(),
    stream_json_tests(),
    stream_binary_tests(),
    stream_gzip_tests(),
    stream_deflate_tests(),
    stream_unknown_encoding_tests(),
  ])
}

fn stream_fast_tests() {
  group("stream_fast", [
    it("returns 200 with Content-Type text/plain", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/fast")

      // Act
      let response = stream_endpoints.stream_fast(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(#(200, [#("content-type", "text/plain")]))
      |> or_fail_with("Expected a text/plain stream with status 200")
    }),
    it("streams Chunk 1 to Chunk 10", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/fast")

      // Act
      let response = stream_endpoints.stream_fast(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> be_equal([
        <<"Chunk 1\n":utf8>>,
        <<"Chunk 2\n":utf8>>,
        <<"Chunk 3\n":utf8>>,
        <<"Chunk 4\n":utf8>>,
        <<"Chunk 5\n":utf8>>,
        <<"Chunk 6\n":utf8>>,
        <<"Chunk 7\n":utf8>>,
        <<"Chunk 8\n":utf8>>,
        <<"Chunk 9\n":utf8>>,
        <<"Chunk 10\n":utf8>>,
      ])
      |> or_fail_with("Expected ten chunks")
    }),
  ])
}

fn stream_slow_tests() {
  group("stream_slow", [
    it("returns 200 with Content-Type text/plain", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/slow")

      // Act
      let response = stream_endpoints.stream_slow(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(#(200, [#("content-type", "text/plain")]))
      |> or_fail_with("Expected a text/plain stream with status 200")
    }),
    it("streams Chunk 1 to Chunk 5", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/slow")

      // Act
      let response = stream_endpoints.stream_slow(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> be_equal([
        <<"Chunk 1\n":utf8>>,
        <<"Chunk 2\n":utf8>>,
        <<"Chunk 3\n":utf8>>,
        <<"Chunk 4\n":utf8>>,
        <<"Chunk 5\n":utf8>>,
      ])
      |> or_fail_with("Expected five chunks")
    }),
  ])
}

fn stream_burst_tests() {
  group("stream_burst", [
    it("returns 200 with Content-Type text/plain", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/burst")

      // Act
      let response = stream_endpoints.stream_burst(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(#(200, [#("content-type", "text/plain")]))
      |> or_fail_with("Expected a text/plain stream with status 200")
    }),
    it("streams Burst 1 to Burst 7", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/burst")

      // Act
      let response = stream_endpoints.stream_burst(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> be_equal([
        <<"Burst 1\n":utf8>>,
        <<"Burst 2\n":utf8>>,
        <<"Burst 3\n":utf8>>,
        <<"Burst 4\n":utf8>>,
        <<"Burst 5\n":utf8>>,
        <<"Burst 6\n":utf8>>,
        <<"Burst 7\n":utf8>>,
      ])
      |> or_fail_with("Expected seven burst chunks")
    }),
  ])
}

fn stream_error_tests() {
  group("stream_error", [
    it("returns 500 with Content-Type text/plain", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/error")

      // Act
      let response = stream_endpoints.stream_error(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(#(500, [#("content-type", "text/plain")]))
      |> or_fail_with("Expected a text/plain stream with status 500")
    }),
    it("streams three error test chunks", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/error")

      // Act
      let response = stream_endpoints.stream_error(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> be_equal([
        <<"Error test chunk 1\n":utf8>>,
        <<"Error test chunk 2\n":utf8>>,
        <<"Error test chunk 3\n":utf8>>,
      ])
      |> or_fail_with("Expected three error test chunks")
    }),
  ])
}

fn stream_drop_tests() {
  group("stream_drop", [
    it("returns 200 with Content-Type text/plain", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/drop")

      // Act
      let response = stream_endpoints.stream_drop(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(#(200, [#("content-type", "text/plain")]))
      |> or_fail_with("Expected a text/plain stream with status 200")
    }),
    it("streams two chunks before it drops the connection", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/drop")

      // Act
      let response = stream_endpoints.stream_drop(request)

      // Assert
      response
      |> should
      |> take_stream_chunks(2)
      |> be_equal([<<"Drop chunk 1\n":utf8>>, <<"Drop chunk 2\n":utf8>>])
      |> or_fail_with("Expected two drop chunks")
    }),
  ])
}

fn stream_huge_tests() {
  group("stream_huge", [
    it("returns 200 with Content-Type text/plain", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/huge")

      // Act
      let response = stream_endpoints.stream_huge(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(#(200, [#("content-type", "text/plain")]))
      |> or_fail_with("Expected a text/plain stream with status 200")
    }),
    it("streams Huge chunk 1 to Huge chunk 100", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/huge")

      // Act
      let response = stream_endpoints.stream_huge(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> be_equal(huge_chunks())
      |> or_fail_with("Expected one hundred huge chunks")
    }),
  ])
}

fn stream_json_tests() {
  group("stream_json", [
    it("returns 200 with Content-Type application/json", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/json")

      // Act
      let response = stream_endpoints.stream_json(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(#(200, [#("content-type", "application/json")]))
      |> or_fail_with("Expected an application/json stream with status 200")
    }),
    it("streams five JSON events, one on each line", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/json")

      // Act
      let response = stream_endpoints.stream_json(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> be_equal([
        <<
          "{\"event\":\"chunk\",\"number\":1,\"message\":\"JSON event 1\"}\n":utf8,
        >>,
        <<
          "{\"event\":\"chunk\",\"number\":2,\"message\":\"JSON event 2\"}\n":utf8,
        >>,
        <<
          "{\"event\":\"chunk\",\"number\":3,\"message\":\"JSON event 3\"}\n":utf8,
        >>,
        <<
          "{\"event\":\"chunk\",\"number\":4,\"message\":\"JSON event 4\"}\n":utf8,
        >>,
        <<
          "{\"event\":\"chunk\",\"number\":5,\"message\":\"JSON event 5\"}\n":utf8,
        >>,
      ])
      |> or_fail_with("Expected five JSON events")
    }),
  ])
}

fn stream_binary_tests() {
  group("stream_binary", [
    it("returns 200 with Content-Type application/octet-stream", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/binary")

      // Act
      let response = stream_endpoints.stream_binary(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(#(200, [#("content-type", "application/octet-stream")]))
      |> or_fail_with("Expected an octet-stream with status 200")
    }),
    it("streams 256 chunks of four equal bytes from 0 to 255", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/binary")

      // Act
      let response = stream_endpoints.stream_binary(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> be_equal(binary_chunks())
      |> or_fail_with("Expected 256 binary chunks")
    }),
  ])
}

fn stream_gzip_tests() {
  group("stream_gzip", [
    it("returns 200 with Content-Encoding gzip", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/gzip")

      // Act
      let response = stream_endpoints.stream_gzip(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(
        #(200, [
          #("content-type", "text/plain"),
          #("content-encoding", "gzip"),
        ]),
      )
      |> or_fail_with("Expected a gzip stream with status 200")
    }),
    it("streams one gzip stream of Chunk 1 to Chunk 5", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/gzip")

      // Act
      let response = stream_endpoints.stream_gzip(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> concatenate_chunks
      |> decompress_with(zlib.gunzip)
      |> be_equal(<<"Chunk 1\nChunk 2\nChunk 3\nChunk 4\nChunk 5\n":utf8>>)
      |> or_fail_with("Expected five chunks after gunzip")
    }),
  ])
}

fn stream_deflate_tests() {
  group("stream_deflate", [
    it("returns 200 with Content-Encoding deflate", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/deflate")

      // Act
      let response = stream_endpoints.stream_deflate(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(
        #(200, [
          #("content-type", "text/plain"),
          #("content-encoding", "deflate"),
        ]),
      )
      |> or_fail_with("Expected a deflate stream with status 200")
    }),
    it("streams one deflate stream of Chunk 1 to Chunk 5", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/deflate")

      // Act
      let response = stream_endpoints.stream_deflate(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> concatenate_chunks
      |> decompress_with(zlib.uncompress)
      |> be_equal(<<"Chunk 1\nChunk 2\nChunk 3\nChunk 4\nChunk 5\n":utf8>>)
      |> or_fail_with("Expected five chunks after inflate")
    }),
  ])
}

fn stream_unknown_encoding_tests() {
  group("stream_unknown_encoding", [
    it("returns 200 with Content-Encoding br", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/unknown-encoding")

      // Act
      let response = stream_endpoints.stream_unknown_encoding(request)

      // Assert
      #(response.status, response.headers)
      |> should
      |> be_equal(
        #(200, [#("content-type", "text/plain"), #("content-encoding", "br")]),
      )
      |> or_fail_with("Expected a br stream with status 200")
    }),
    it("streams Raw 1 to Raw 5 without compression", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/unknown-encoding")

      // Act
      let response = stream_endpoints.stream_unknown_encoding(request)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> be_equal([
        <<"Raw 1\n":utf8>>,
        <<"Raw 2\n":utf8>>,
        <<"Raw 3\n":utf8>>,
        <<"Raw 4\n":utf8>>,
        <<"Raw 5\n":utf8>>,
      ])
      |> or_fail_with("Expected five raw chunks")
    }),
  ])
}
