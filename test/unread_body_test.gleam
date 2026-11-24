//// Tests that bytes of a request body are never answered as a request.
////
//// Each test sends the head of a request whose body is the text of a second
//// request, `GET /text`. It reads the first answer, then sends the body
//// bytes on the same connection. When the server answers without a read of
//// the body, it must close the connection: the body bytes must not get an
//// answer. When the server reads the body, the bytes are the body and get no
//// answer of their own. The control sends a real second request after a body
//// that the server read, and gets a second answer.

import dream_mock_server/config.{Exact, MockRoute}
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/http.{Exchange, ServerClosed, StillOpen}
import fixtures/port
import gleam/http as gleam_http
import gleam/int
import gleam/option.{Some}
import gleam/string

/// The request that the body bytes of each test spell out.
const smuggled_request = "GET /text HTTP/1.1\r\nhost: localhost\r\n\r\n"

pub fn tests() -> TestSuite {
  describe("a request body as a request", [
    unread_body_tests(),
    read_body_tests(),
    control_tests(),
  ])
}

fn unread_body_tests() {
  group("a body that the server does not read", [
    it("built-in mode, no route: closes after the 404", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)

      // Act
      let exchange =
        http.raw_exchange(
          port,
          head_with_length("POST", "/no-such-route"),
          smuggled_request,
        )
      server.stop(handle)

      // Assert
      exchange
      |> should
      |> be_equal(
        Ok(Exchange(
          first_answer: route_not_found_closed,
          later_answer: "",
          ending: ServerClosed,
        )),
      )
      |> or_fail_with("Expected one 404 and a closed connection")
    }),
    it("built-in mode, POST to a GET endpoint: closes after the 404", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)

      // Act
      let exchange =
        http.raw_exchange(
          port,
          head_with_length("POST", "/get"),
          smuggled_request,
        )
      server.stop(handle)

      // Assert
      exchange
      |> should
      |> be_equal(
        Ok(Exchange(
          first_answer: route_not_found_closed,
          later_answer: "",
          ending: ServerClosed,
        )),
      )
      |> or_fail_with("Expected one 404 and a closed connection")
    }),
    it("built-in mode, chunked body, no route: closes after the 404", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)
      let head =
        "POST /no-such-route HTTP/1.1\r\nhost: localhost\r\ntransfer-encoding: chunked\r\n\r\n"

      // Act
      let exchange = http.raw_exchange(port, head, smuggled_request)
      server.stop(handle)

      // Assert
      exchange
      |> should
      |> be_equal(
        Ok(Exchange(
          first_answer: route_not_found_closed,
          later_answer: "",
          ending: ServerClosed,
        )),
      )
      |> or_fail_with("Expected one 404 and a closed connection")
    }),
    it("a body larger than 10 MB: closes after the 400", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)
      let head =
        "POST /post HTTP/1.1\r\nhost: localhost\r\ncontent-length: 10000001\r\n\r\n"

      // Act
      let exchange = http.raw_exchange(port, head, smuggled_request)
      server.stop(handle)

      // Assert
      exchange
      |> should
      |> be_equal(
        Ok(Exchange(
          first_answer: "HTTP/1.1 400 Bad Request\r\nconnection: close\r\ncontent-length: 0\r\n\r\n",
          later_answer: "",
          ending: ServerClosed,
        )),
      )
      |> or_fail_with("Expected one 400 and a closed connection")
    }),
  ])
}

fn read_body_tests() {
  group("a body that the server reads and does not use", [
    it("built-in mode, GET /json with a body: one answer", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = server.start(port)

      // Act
      let exchange =
        http.raw_exchange(
          port,
          head_with_length("GET", "/json"),
          smuggled_request,
        )
      server.stop(handle)

      // Assert
      exchange
      |> should
      |> be_equal(
        Ok(Exchange(
          first_answer: "",
          later_answer: "HTTP/1.1 200 OK\r\ncontent-type: application/json; charset=utf-8\r\ncontent-length: 42\r\nconnection: keep-alive\r\n\r\n{\"message\":\"Hello, World!\",\"success\":true}",
          ending: StillOpen,
        )),
      )
      |> or_fail_with("Expected only the GET /json answer")
    }),
    it("config mode, no route: one 404", fn() {
      // Arrange
      let port = port.free_port()
      let routes = [MockRoute("/hook", Exact, Some(gleam_http.Post), 202, "ok")]
      let assert Ok(handle) = server.start_with_config(port, routes)

      // Act
      let exchange =
        http.raw_exchange(
          port,
          head_with_length("POST", "/no-such-route"),
          smuggled_request,
        )
      server.stop(handle)

      // Assert
      exchange
      |> should
      |> be_equal(
        Ok(Exchange(
          first_answer: "",
          later_answer: "HTTP/1.1 404 Not Found\r\ncontent-type: text/plain; charset=utf-8\r\ncontent-length: 9\r\nconnection: keep-alive\r\n\r\nNot found",
          ending: StillOpen,
        )),
      )
      |> or_fail_with("Expected only the 404 Not found answer")
    }),
    it("config mode, a route that does not use the body: one answer", fn() {
      // Arrange
      let port = port.free_port()
      let routes = [MockRoute("/hook", Exact, Some(gleam_http.Post), 202, "ok")]
      let assert Ok(handle) = server.start_with_config(port, routes)

      // Act
      let exchange =
        http.raw_exchange(
          port,
          head_with_length("POST", "/hook"),
          smuggled_request,
        )
      server.stop(handle)

      // Assert
      exchange
      |> should
      |> be_equal(
        Ok(Exchange(
          first_answer: "",
          later_answer: "HTTP/1.1 202 Accepted\r\ncontent-type: text/plain; charset=utf-8\r\ncontent-length: 2\r\nconnection: keep-alive\r\n\r\nok",
          ending: StillOpen,
        )),
      )
      |> or_fail_with("Expected only the route answer")
    }),
  ])
}

fn control_tests() {
  group("control", [
    it(
      "a second request after a body that the server read gets an answer",
      fn() {
        // Arrange
        let port = port.free_port()
        let assert Ok(handle) = server.start(port)
        let echo_request =
          "POST /post HTTP/1.1\r\nhost: localhost\r\ncontent-length: 5\r\n\r\nhello"

        // Act
        let exchange = http.raw_exchange(port, echo_request, smuggled_request)
        server.stop(handle)

        // Assert
        exchange
        |> should
        |> be_equal(
          Ok(Exchange(
            first_answer: "HTTP/1.1 201 Created\r\ncontent-type: application/json; charset=utf-8\r\ncontent-length: 46\r\nconnection: keep-alive\r\n\r\n{\"method\":\"POST\",\"url\":\"/post\",\"data\":\"hello\"}",
            later_answer: "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\ncontent-length: 13\r\nconnection: keep-alive\r\n\r\nHello, World!",
            ending: StillOpen,
          )),
        )
        |> or_fail_with("Expected the echo answer, then the GET /text answer")
      },
    ),
  ])
}

/// The answer to a request that matches no built-in endpoint, when the
/// server closes the connection after it.
const route_not_found_closed =
  "HTTP/1.1 404 Not Found\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 15\r\n\r\nRoute not found"

/// The head of a request whose `content-length` is the length of
/// `smuggled_request`.
fn head_with_length(method: String, path: String) -> String {
  method
  <> " "
  <> path
  <> " HTTP/1.1\r\nhost: localhost\r\ncontent-length: "
  <> int.to_string(string.byte_size(smuggled_request))
  <> "\r\n\r\n"
}
