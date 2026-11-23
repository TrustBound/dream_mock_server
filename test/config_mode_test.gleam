//// Tests of config mode (`server.start_with_config`) over real HTTP
//// connections: path matching (exact, prefix, first match), method
//// filtering, status and body, and requests that match no route.

import dream/http/request.{Get, Post}
import dream_mock_server/config.{Exact, MockRoute, Prefix}
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/http
import fixtures/port
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
  ])
}
