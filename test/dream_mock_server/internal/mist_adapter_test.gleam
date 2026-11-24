//// Tests of the mist adapter over real connections: the body read and the
//// answers that come from the adapter and not from an endpoint.

import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/http
import fixtures/port

pub fn tests() -> TestSuite {
  describe("dream_mock_server/internal/mist_adapter", [
    group("handler", [
      it("answers 400 when the body is larger than 10 MB", fn() {
        // Arrange
        let port = port.free_port()
        let assert Ok(handle) = server.start(port)
        let request =
          "POST /post HTTP/1.1\r\nhost: localhost\r\ncontent-length: 10000001\r\nconnection: close\r\n\r\n"

        // Act
        let status_line = http.raw_status_line(port, request)
        server.stop(handle)

        // Assert
        status_line
        |> should
        |> be_equal(Ok("HTTP/1.1 400 Bad Request"))
        |> or_fail_with("Expected 400 for a body that is too large")
      }),
      it("answers 404 for an unknown path without a body read", fn() {
        // Arrange
        let port = port.free_port()
        let assert Ok(handle) = server.start(port)
        let request =
          "POST /nope HTTP/1.1\r\nhost: localhost\r\ncontent-length: 10000001\r\nconnection: close\r\n\r\n"

        // Act
        let status_line = http.raw_status_line(port, request)
        server.stop(handle)

        // Assert
        status_line
        |> should
        |> be_equal(Ok("HTTP/1.1 404 Not Found"))
        |> or_fail_with("Expected 404 before the body read")
      }),
      it("answers a HEAD request with 404", fn() {
        // Arrange
        let port = port.free_port()
        let assert Ok(handle) = server.start(port)
        let request =
          "HEAD /text HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let status_line = http.raw_status_line(port, request)
        server.stop(handle)

        // Assert
        status_line
        |> should
        |> be_equal(Ok("HTTP/1.1 404 Not Found"))
        |> or_fail_with("Expected 404 for HEAD")
      }),
      it("answers HEAD on a built-in path with 404 headers and no body", fn() {
        // Arrange
        let port = port.free_port()
        let assert Ok(handle) = server.start(port)
        let request =
          "HEAD /text HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let answer = http.raw_answer(port, request)
        server.stop(handle)

        // Assert
        answer
        |> should
        |> be_equal(Ok(
          "HTTP/1.1 404 Not Found\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 15\r\n\r\n",
        ))
        |> or_fail_with("Expected the 404 headers and no body bytes")
      }),
      it("answers OPTIONS on a built-in path with 404 Route not found", fn() {
        // Arrange
        let port = port.free_port()
        let assert Ok(handle) = server.start(port)
        let request =
          "OPTIONS /text HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let answer = http.raw_answer(port, request)
        server.stop(handle)

        // Assert
        answer
        |> should
        |> be_equal(Ok(
          "HTTP/1.1 404 Not Found\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 15\r\n\r\nRoute not found",
        ))
        |> or_fail_with("Expected 404 Route not found")
      }),
    ]),
  ])
}
