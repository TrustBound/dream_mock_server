//// README: Integration Testing
////
//// A test that runs against the mock server on a free port.

import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/types.{type TestSuite}
import dream_test/unit.{describe, it}
import gleam/int
import snippets/http_helper
import snippets/port

pub fn tests() -> TestSuite(Nil) {
  describe("mock server", [
    it("streams ten chunks from /stream/fast", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(mock) = server.start(port)

      // Act: send the request to http://localhost:<port>
      let response =
        http_helper.get(
          "http://localhost:" <> int.to_string(port) <> "/stream/fast",
        )
      server.stop(mock)

      // Assert
      response
      |> should
      |> be_equal(
        Ok(#(
          200,
          "Chunk 1\nChunk 2\nChunk 3\nChunk 4\nChunk 5\nChunk 6\nChunk 7\nChunk 8\nChunk 9\nChunk 10\n",
        )),
      )
      |> or_fail_with("Expected ten chunks from /stream/fast")
    }),
  ])
}
