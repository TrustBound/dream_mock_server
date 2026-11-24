//// Tests of the server lifecycle: start, start_with_config and stop, over
//// real HTTP connections on free ports.

import dream_mock_server/config.{Exact, MockRoute}
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/http
import fixtures/port
import gleam/int
import gleam/option.{None}
import gleam/otp/actor

pub fn tests() -> TestSuite {
  describe("dream_mock_server/server", [
    start_tests(),
    start_with_config_tests(),
    stop_tests(),
    method_tests(),
  ])
}

fn start_tests() {
  group("start", [
    it("serves the built-in endpoints on the given port", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)

      // Act
      let response = http.get(http.url(port, "/text"))
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "Hello, World!")))
      |> or_fail_with("Expected 200 with Hello, World!")
    }),
    it("echoes a POST body as JSON", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)

      // Act
      let response = http.send("POST", http.url(port, "/post"), "hello")
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(
        Ok(#(201, "{\"method\":\"POST\",\"url\":\"/post\",\"data\":\"hello\"}")),
      )
      |> or_fail_with("Expected 201 with the POST echo JSON")
    }),
    it("runs two servers on two ports at the same time", fn() {
      // Arrange
      let first_port = port.free_port()
      let second_port = port.free_port()
      let assert Ok(first_handle) = server.start(first_port)
      let assert Ok(second_handle) = server.start(second_port)

      // Act
      let responses = #(
        http.get(http.url(first_port, "/text")),
        http.get(http.url(second_port, "/text")),
      )
      server.stop(first_handle)
      server.stop(second_handle)

      // Assert
      responses
      |> should
      |> be_equal(#(Ok(#(200, "Hello, World!")), Ok(#(200, "Hello, World!"))))
      |> or_fail_with("Expected both servers to answer")
    }),
    it("starts again on a port after a stop", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(first_handle) = server.start(port)
      server.stop(first_handle)
      let assert Ok(second_handle) = server.start(port)

      // Act
      let response = http.get(http.url(port, "/text"))
      server.stop(second_handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "Hello, World!")))
      |> or_fail_with("Expected the second server to answer")
    }),
    it("returns InitFailed when the port is in use", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)

      // Act
      let result = server.start(port)
      server.stop(handle)

      // Assert
      result
      |> should
      |> be_equal(
        Error(actor.InitFailed(
          "Port "
          <> int.to_string(port)
          <> " already in use on localhost. Stop the process using that port or choose a different one.",
        )),
      )
      |> or_fail_with("Expected InitFailed for a port in use")
    }),
    it("closes the connection when /stream/drop crashes mid-stream", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)

      // Act
      let response = http.get(http.url(port, "/stream/drop"))
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Error("socket_closed_remotely"))
      |> or_fail_with("Expected the connection to close")
    }),
  ])
}

fn start_with_config_tests() {
  group("start_with_config", [
    it("serves the configured routes", fn() {
      // Arrange
      let port = port.free_port()
      let routes = [MockRoute("/x", Exact, None, 200, "x")]
      let assert Ok(handle) = server.start_with_config(port, routes)

      // Act
      let response = http.get(http.url(port, "/x"))
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "x")))
      |> or_fail_with("Expected 200 with x")
    }),
    it("returns InitFailed when the port is in use", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)

      // Act
      let result = server.start_with_config(port, [])
      server.stop(handle)

      // Assert
      result
      |> should
      |> be_equal(
        Error(actor.InitFailed(
          "Port "
          <> int.to_string(port)
          <> " already in use on localhost. Stop the process using that port or choose a different one.",
        )),
      )
      |> or_fail_with("Expected InitFailed for a port in use")
    }),
    it("does not serve the built-in endpoints", fn() {
      // Arrange
      let port = port.free_port()
      let routes = [MockRoute("/x", Exact, None, 200, "x")]
      let assert Ok(handle) = server.start_with_config(port, routes)

      // Act
      let response = http.get(http.url(port, "/text"))
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(404, "Not found")))
      |> or_fail_with("Expected 404 Not found")
    }),
    it("starts again on a port after a stop", fn() {
      // Arrange
      let port = port.free_port()
      let routes = [MockRoute("/x", Exact, None, 200, "x")]
      let assert Ok(first_handle) = server.start_with_config(port, routes)
      server.stop(first_handle)
      let assert Ok(second_handle) = server.start_with_config(port, routes)

      // Act
      let response = http.get(http.url(port, "/x"))
      server.stop(second_handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "x")))
      |> or_fail_with("Expected the second server to answer")
    }),
  ])
}

fn stop_tests() {
  group("stop", [
    it("closes the port", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)

      // Act
      server.stop(handle)
      let response = http.get(http.url(port, "/text"))

      // Assert
      response
      |> should
      |> be_equal(Error("econnrefused"))
      |> or_fail_with("Expected the connection to be refused")
    }),
    it("returns Nil for a server that is already stopped", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)
      server.stop(handle)

      // Act
      let result = server.stop(handle)

      // Assert
      result
      |> should
      |> be_equal(Nil)
      |> or_fail_with("Expected Nil")
    }),
  ])
}

fn method_tests() {
  group("request methods of the built-in endpoints", [
    it("answers 404 Route not found for DELETE /text", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)
      let request =
        "DELETE /text HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

      // Act
      let answer = http.raw_status_and_body(port, request)
      server.stop(handle)

      // Assert
      answer
      |> should
      |> be_equal(Ok(#("HTTP/1.1 404 Not Found", "Route not found")))
      |> or_fail_with("Expected 404 Route not found for DELETE /text")
    }),
    it("answers 404 Route not found for PURGE /text", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)
      let request =
        "PURGE /text HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

      // Act
      let answer = http.raw_status_and_body(port, request)
      server.stop(handle)

      // Assert
      answer
      |> should
      |> be_equal(Ok(#("HTTP/1.1 404 Not Found", "Route not found")))
      |> or_fail_with("Expected 404 Route not found for PURGE /text")
    }),
    it("answers 404 Route not found for TRACE /text", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)
      let request =
        "TRACE /text HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

      // Act
      let answer = http.raw_status_and_body(port, request)
      server.stop(handle)

      // Assert
      answer
      |> should
      |> be_equal(Ok(#("HTTP/1.1 404 Not Found", "Route not found")))
      |> or_fail_with("Expected 404 Route not found for TRACE /text")
    }),
    it("answers 404 Route not found for CONNECT /text", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)
      let request =
        "CONNECT /text HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

      // Act
      let answer = http.raw_status_and_body(port, request)
      server.stop(handle)

      // Assert
      answer
      |> should
      |> be_equal(Ok(#("HTTP/1.1 404 Not Found", "Route not found")))
      |> or_fail_with("Expected 404 Route not found for CONNECT /text")
    }),
    it("closes the connection for CONNECT to an authority", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)
      let request =
        "CONNECT localhost:443 HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

      // Act
      let answer = http.raw_status_and_body(port, request)
      server.stop(handle)

      // Assert
      answer
      |> should
      |> be_equal(Ok(#("", "")))
      |> or_fail_with("Expected no answer for CONNECT localhost:443")
    }),
  ])
}
