//// Tests of config mode (`server.start_with_config`) over real HTTP
//// connections: path matching (exact, prefix, first match), method
//// filtering, status and body, and requests that match no route.

import dream_mock_server/config.{type MockRoute, Exact, MockRoute, Prefix}
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/http
import fixtures/port
import gleam/http.{Connect, Get, Head, Options, Other, Post, Trace} as _gleam_http
import gleam/option.{None, Some}

pub fn tests() -> TestSuite {
  describe("config mode", [
    group("path matching", [
      it("returns the route of an exact path", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/foo", Exact, None, 200, "exact-foo")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/foo"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "exact-foo")))
        |> or_fail_with("Expected Ok(#(200, 'exact-foo'))")
      }),
      it("returns 404 for a longer path of an exact route", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/foo", Exact, None, 200, "ok")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/foo/bar"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(404, "Not found")))
        |> or_fail_with("Expected Ok(#(404, 'Not found'))")
      }),
      it("returns the prefix route for the prefix itself", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/api", Prefix, None, 200, "api")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/api"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "api")))
        |> or_fail_with("Expected Ok(#(200, 'api'))")
      }),
      it("returns the prefix route for a longer path", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/api", Prefix, None, 200, "api")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/api/v1/chat"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "api")))
        |> or_fail_with("Expected Ok(#(200, 'api'))")
      }),
      it("returns 404 for a path outside the prefix", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/api", Prefix, None, 200, "api")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/other"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(404, "Not found")))
        |> or_fail_with("Expected Ok(#(404, 'Not found'))")
      }),
    ]),
    group("route order", [
      it("returns the first route that matches", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/api/special", Exact, None, 200, "special"),
          MockRoute("/api", Prefix, None, 200, "api"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/api/special"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "special")))
        |> or_fail_with("Expected Ok(#(200, 'special'))")
      }),
      it("returns a later route when an earlier one does not match", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/api/special", Exact, None, 200, "special"),
          MockRoute("/api", Prefix, None, 200, "api"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/api/other"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "api")))
        |> or_fail_with("Expected Ok(#(200, 'api'))")
      }),
    ]),
    group("method filtering", [
      it("matches GET when the route has no method", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/any", Exact, None, 200, "ok")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/any"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "ok")))
        |> or_fail_with("Expected Ok(#(200, 'ok'))")
      }),
      it("matches POST when the route has no method", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/any", Exact, None, 200, "ok")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.send("POST", http.url(port, "/any"), "")
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "ok")))
        |> or_fail_with("Expected Ok(#(200, 'ok'))")
      }),
      it("matches the method of the route", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/post-only", Exact, Some(Post), 201, "created"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.send("POST", http.url(port, "/post-only"), "")
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(201, "created")))
        |> or_fail_with("Expected Ok(#(201, 'created'))")
      }),
      it("returns 404 for another method", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/post-only", Exact, Some(Post), 201, "created"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/post-only"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(404, "Not found")))
        |> or_fail_with("Expected Ok(#(404, 'Not found'))")
      }),
      it("returns the GET route of a path with two methods", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/r", Exact, Some(Get), 200, "get"),
          MockRoute("/r", Exact, Some(Post), 201, "post"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/r"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "get")))
        |> or_fail_with("Expected Ok(#(200, 'get'))")
      }),
      it("returns the POST route of a path with two methods", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/r", Exact, Some(Get), 200, "get"),
          MockRoute("/r", Exact, Some(Post), 201, "post"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.send("POST", http.url(port, "/r"), "")
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(201, "post")))
        |> or_fail_with("Expected Ok(#(201, 'post'))")
      }),
    ]),
    group("request methods", [
      it("matches a PURGE request to a route with the method PURGE", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/cache", Exact, Some(Other("PURGE")), 200, "purged"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)
        let request =
          "PURGE /cache HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let answer = http.raw_status_and_body(port, request)
        server.stop(handle)

        // Assert
        answer
        |> should
        |> be_equal(Ok(#("HTTP/1.1 200 OK", "purged")))
        |> or_fail_with("Expected the PURGE route to answer")
      }),
      it("matches a TRACE request to a route with the method TRACE", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/trace", Exact, Some(Trace), 200, "traced")]
        let assert Ok(handle) = server.start_with_config(port, routes)
        let request =
          "TRACE /trace HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let answer = http.raw_status_and_body(port, request)
        server.stop(handle)

        // Assert
        answer
        |> should
        |> be_equal(Ok(#("HTTP/1.1 200 OK", "traced")))
        |> or_fail_with("Expected the TRACE route to answer")
      }),
      it("matches a CONNECT request to a route with the method CONNECT", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/tunnel", Exact, Some(Connect), 200, "tunnel")]
        let assert Ok(handle) = server.start_with_config(port, routes)
        let request =
          "CONNECT /tunnel HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let answer = http.raw_status_and_body(port, request)
        server.stop(handle)

        // Assert
        answer
        |> should
        |> be_equal(Ok(#("HTTP/1.1 200 OK", "tunnel")))
        |> or_fail_with("Expected the CONNECT route to answer")
      }),
      it("matches a PURGE request to a route with no method", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/cache", Exact, None, 200, "any")]
        let assert Ok(handle) = server.start_with_config(port, routes)
        let request =
          "PURGE /cache HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let answer = http.raw_status_and_body(port, request)
        server.stop(handle)

        // Assert
        answer
        |> should
        |> be_equal(Ok(#("HTTP/1.1 200 OK", "any")))
        |> or_fail_with("Expected the route with no method to answer")
      }),
      it("returns 404 for a TRACE request to a GET route", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/x", Exact, Some(Get), 200, "x")]
        let assert Ok(handle) = server.start_with_config(port, routes)
        let request =
          "TRACE /x HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let answer = http.raw_status_and_body(port, request)
        server.stop(handle)

        // Assert
        answer
        |> should
        |> be_equal(Ok(#("HTTP/1.1 404 Not Found", "Not found")))
        |> or_fail_with("Expected 404 Not found for TRACE")
      }),
      it("returns 404 for a PURGE request to a GET route", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/x", Exact, Some(Get), 200, "x")]
        let assert Ok(handle) = server.start_with_config(port, routes)
        let request =
          "PURGE /x HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let answer = http.raw_status_and_body(port, request)
        server.stop(handle)

        // Assert
        answer
        |> should
        |> be_equal(Ok(#("HTTP/1.1 404 Not Found", "Not found")))
        |> or_fail_with("Expected 404 Not found for PURGE")
      }),
      it("matches the method name with its case", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/cache", Exact, Some(Other("PURGE")), 200, "purged"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)
        let request =
          "Purge /cache HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

        // Act
        let answer = http.raw_status_and_body(port, request)
        server.stop(handle)

        // Assert
        answer
        |> should
        |> be_equal(Ok(#("HTTP/1.1 404 Not Found", "Not found")))
        |> or_fail_with("Expected 404 Not found for Purge")
      }),
      it("closes the connection for CONNECT to an authority", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/", Prefix, None, 200, "any")]
        let assert Ok(handle) = server.start_with_config(port, routes)
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
    ]),
    group("status and body", [
      it("returns a 201 status", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/created", Exact, None, 201, "created")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/created"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(201, "created")))
        |> or_fail_with("Expected Ok(#(201, 'created'))")
      }),
      it("returns a 500 status", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/error", Exact, None, 500, "server error")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/error"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(500, "server error")))
        |> or_fail_with("Expected Ok(#(500, 'server error'))")
      }),
      it("returns an empty body", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [MockRoute("/empty", Exact, None, 200, "")]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/empty"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "")))
        |> or_fail_with("Expected Ok(#(200, ''))")
      }),
      it("returns a JSON body as it is", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/json", Exact, None, 200, "{\"key\":\"value\"}"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/json"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "{\"key\":\"value\"}")))
        |> or_fail_with("Expected the JSON body as it is")
      }),
    ]),
    group("no match", [
      it("returns 404 for a path with no route", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/a", Exact, None, 200, "a"),
          MockRoute("/b", Exact, None, 200, "b"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/c"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(404, "Not found")))
        |> or_fail_with("Expected Ok(#(404, 'Not found'))")
      }),
      it("returns 404 for the root path with no route", fn() {
        // Arrange
        let port = port.free_port()
        let routes = [
          MockRoute("/a", Exact, None, 200, "a"),
          MockRoute("/b", Exact, None, 200, "b"),
        ]
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(404, "Not found")))
        |> or_fail_with("Expected Ok(#(404, 'Not found'))")
      }),
      it("returns 404 for every path of an empty config", fn() {
        // Arrange
        let port = port.free_port()
        let routes = []
        let assert Ok(handle) = server.start_with_config(port, routes)

        // Act
        let response = http.get(http.url(port, "/anything"))
        server.stop(handle)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(404, "Not found")))
        |> or_fail_with("Expected Ok(#(404, 'Not found'))")
      }),
    ]),
    head_and_options_tests(),
  ])
}

fn head_and_options_tests() {
  group("HEAD and OPTIONS", [
    it("answers a CORS preflight with the OPTIONS route", fn() {
      // Arrange
      let routes = preflight_routes()

      // Act
      let answer = raw_answer_with_routes(routes, "OPTIONS /api/items")

      // Assert
      answer
      |> should
      |> be_equal(Ok(
        "HTTP/1.1 204 No Content\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\n\r\n",
      ))
      |> or_fail_with("Expected 204 with no body and no content-length")
    }),
    it("answers GET on the path of the preflight with the GET route", fn() {
      // Arrange
      let routes = preflight_routes()

      // Act
      let answer = raw_answer_with_routes(routes, "GET /api/items")

      // Assert
      answer
      |> should
      |> be_equal(Ok(
        "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 2\r\n\r\n[]",
      ))
      |> or_fail_with("Expected 200 with the body []")
    }),
    it("answers HEAD with a HEAD route: headers and no body", fn() {
      // Arrange
      let routes = [MockRoute("/file", Exact, Some(Head), 200, "hello")]

      // Act
      let answer = raw_answer_with_routes(routes, "HEAD /file")

      // Assert
      answer
      |> should
      |> be_equal(Ok(
        "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 5\r\n\r\n",
      ))
      |> or_fail_with("Expected the headers of the route and no body bytes")
    }),
    it("does not answer GET with a HEAD route", fn() {
      // Arrange
      let routes = [MockRoute("/file", Exact, Some(Head), 200, "hello")]

      // Act
      let answer = raw_answer_with_routes(routes, "GET /file")

      // Assert
      answer
      |> should
      |> be_equal(Ok(not_found_answer))
      |> or_fail_with("Expected 404 Not found")
    }),
    it("does not answer HEAD with a GET route", fn() {
      // Arrange
      let routes = [MockRoute("/file", Exact, Some(Get), 200, "hello")]

      // Act
      let answer = raw_answer_with_routes(routes, "HEAD /file")

      // Assert
      answer
      |> should
      |> be_equal(Ok(not_found_head_answer))
      |> or_fail_with("Expected the 404 Not found headers and no body bytes")
    }),
    it("answers HEAD and GET with a route of every method", fn() {
      // Arrange
      let routes = [MockRoute("/file", Exact, None, 200, "hello")]

      // Act
      let answers = #(
        raw_answer_with_routes(routes, "HEAD /file"),
        raw_answer_with_routes(routes, "GET /file"),
      )

      // Assert
      answers
      |> should
      |> be_equal(#(
        Ok(
          "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 5\r\n\r\n",
        ),
        Ok(
          "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 5\r\n\r\nhello",
        ),
      ))
      |> or_fail_with("Expected the GET headers for HEAD, with no body")
    }),
    it("answers OPTIONS with a route of every method", fn() {
      // Arrange
      let routes = [MockRoute("/file", Exact, None, 200, "hello")]

      // Act
      let answer = raw_answer_with_routes(routes, "OPTIONS /file")

      // Assert
      answer
      |> should
      |> be_equal(Ok(
        "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 5\r\n\r\nhello",
      ))
      |> or_fail_with("Expected 200 with the body hello")
    }),
    it("answers HEAD with no route: 404 Not found headers, no body", fn() {
      // Arrange
      let routes = [MockRoute("/file", Exact, Some(Post), 200, "hello")]

      // Act
      let answer = raw_answer_with_routes(routes, "HEAD /nope")

      // Assert
      answer
      |> should
      |> be_equal(Ok(not_found_head_answer))
      |> or_fail_with("Expected the 404 Not found headers and no body bytes")
    }),
    it("answers OPTIONS with no route: 404 Not found", fn() {
      // Arrange
      let routes = [MockRoute("/file", Exact, Some(Post), 200, "hello")]

      // Act
      let answer = raw_answer_with_routes(routes, "OPTIONS /nope")

      // Assert
      answer
      |> should
      |> be_equal(Ok(not_found_answer))
      |> or_fail_with("Expected 404 Not found")
    }),
    it("sends a 204 route with no body and no content-length", fn() {
      // Arrange
      let routes = [MockRoute("/gone", Exact, None, 204, "")]

      // Act
      let answer = raw_answer_with_routes(routes, "GET /gone")

      // Assert
      answer
      |> should
      |> be_equal(Ok(
        "HTTP/1.1 204 No Content\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\n\r\n",
      ))
      |> or_fail_with("Expected 204 with no body and no content-length")
    }),
  ])
}

/// An OPTIONS route that answers a CORS preflight with 204, and a GET route
/// on the same path.
fn preflight_routes() -> List(MockRoute) {
  [
    MockRoute("/api/items", Exact, Some(Options), 204, ""),
    MockRoute("/api/items", Exact, Some(Get), 200, "[]"),
  ]
}

/// The config mode answer when no route matches, on a connection that
/// closes after it.
const not_found_answer =
  "HTTP/1.1 404 Not Found\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 9\r\n\r\nNot found"

/// The answer to HEAD when no route matches: the headers of
/// `not_found_answer` and no body.
const not_found_head_answer =
  "HTTP/1.1 404 Not Found\r\ncontent-type: text/plain; charset=utf-8\r\nconnection: close\r\ncontent-length: 9\r\n\r\n"

/// Starts config mode with `routes`, sends one request with the request
/// line `method_and_path`, and returns every byte of the answer without the
/// `date` header line.
fn raw_answer_with_routes(
  routes: List(MockRoute),
  method_and_path: String,
) -> Result(String, String) {
  let port = port.free_port()
  let assert Ok(handle) = server.start_with_config(port, routes)
  let answer =
    http.raw_answer(
      port,
      method_and_path
        <> " HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n",
    )
  server.stop(handle)
  answer
}
