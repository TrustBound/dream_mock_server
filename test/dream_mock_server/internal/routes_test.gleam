import dream_mock_server/config.{Exact, MockRoute, Prefix}
import dream_mock_server/internal/api_endpoints
import dream_mock_server/internal/built_in_endpoints.{
  type Segment, Literal, Parameter,
}
import dream_mock_server/internal/message.{
  type Request, type Response, json_response, text_response,
}
import dream_mock_server/internal/routes.{
  type Mode, BuiltInEndpoints, ConfiguredRoutes,
}
import dream_mock_server/internal/stream_endpoints
import dream_mock_server/views/index_view
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/request as test_request
import gleam/http.{
  Connect, Delete, Get, Head, Options, Other, Patch, Post, Put, Trace,
}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// Answers a request through `routes.answer`, with the body of the request
/// as the body that the server reads.
fn answer_request(mode: Mode, request: Request) -> Response {
  routes.answer(mode, test_request.head_of(request), fn() { Ok(request.body) })
}

pub fn tests() -> TestSuite {
  describe("dream_mock_server/internal/routes", [
    group("answer with the built-in endpoints", [
      it("sends GET / to routes.index", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(routes.index(request))
        |> or_fail_with("Expected the response of routes.index")
      }),
      it("sends GET /get to api_endpoints.get", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/get")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.get(request))
        |> or_fail_with("Expected the response of api_endpoints.get")
      }),
      it("sends POST /post to api_endpoints.post", fn() {
        // Arrange
        let request = test_request.create_request(Post, "/post")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.post(request))
        |> or_fail_with("Expected the response of api_endpoints.post")
      }),
      it("sends POST /content-type to api_endpoints.content_type", fn() {
        // Arrange
        let request = test_request.create_request(Post, "/content-type")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.content_type(request))
        |> or_fail_with("Expected the response of api_endpoints.content_type")
      }),
      it("sends PUT /put to api_endpoints.put", fn() {
        // Arrange
        let request = test_request.create_request(Put, "/put")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.put(request))
        |> or_fail_with("Expected the response of api_endpoints.put")
      }),
      it("sends PATCH /patch to api_endpoints.patch", fn() {
        // Arrange
        let request = test_request.create_request(Patch, "/patch")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.patch(request))
        |> or_fail_with("Expected the response of api_endpoints.patch")
      }),
      it("sends DELETE /delete to api_endpoints.delete", fn() {
        // Arrange
        let request = test_request.create_request(Delete, "/delete")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.delete(request))
        |> or_fail_with("Expected the response of api_endpoints.delete")
      }),
      it("sends GET /json to api_endpoints.json_endpoint", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/json")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.json_endpoint(request))
        |> or_fail_with("Expected the response of api_endpoints.json_endpoint")
      }),
      it("sends GET /text to api_endpoints.text", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/text")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.text(request))
        |> or_fail_with("Expected the response of api_endpoints.text")
      }),
      it("sends GET /uuid to api_endpoints.uuid", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/uuid")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.uuid(request))
        |> or_fail_with("Expected the response of api_endpoints.uuid")
      }),
      it("sends GET /status/:code to api_endpoints.status", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/status/418")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(json_response(418, "{\"status\":418}"))
        |> or_fail_with("Expected 418 with the status JSON")
      }),
      it("sends GET /large to api_endpoints.large", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/large")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.large(request))
        |> or_fail_with("Expected the response of api_endpoints.large")
      }),
      it("sends GET /empty to api_endpoints.empty", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/empty")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.empty(request))
        |> or_fail_with("Expected the response of api_endpoints.empty")
      }),
      it("sends GET /slow to the slow endpoint", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/slow")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "Slow response"))
        |> or_fail_with("Expected the slow response")
      }),
      it("sends GET /gzip to api_endpoints.gzip", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/gzip")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.gzip(request))
        |> or_fail_with("Expected the response of api_endpoints.gzip")
      }),
      it("sends GET /deflate to api_endpoints.deflate", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/deflate")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.deflate(request))
        |> or_fail_with("Expected the response of api_endpoints.deflate")
      }),
      it("sends GET /identity to api_endpoints.identity", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/identity")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.identity(request))
        |> or_fail_with("Expected the response of api_endpoints.identity")
      }),
      it("sends GET /unknown-encoding to api_endpoints.unknown_encoding", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/unknown-encoding")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.unknown_encoding(request))
        |> or_fail_with(
          "Expected the response of api_endpoints.unknown_encoding",
        )
      }),
      it("sends GET /corrupted-gzip to api_endpoints.corrupted_gzip", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/corrupted-gzip")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.corrupted_gzip(request))
        |> or_fail_with("Expected the response of api_endpoints.corrupted_gzip")
      }),
      it(
        "sends GET /echo-accept-encoding to api_endpoints.echo_accept_encoding",
        fn() {
          // Arrange
          let request =
            test_request.create_request(Get, "/echo-accept-encoding")

          // Act
          let response = answer_request(BuiltInEndpoints, request)

          // Assert
          response
          |> should
          |> be_equal(api_endpoints.echo_accept_encoding(request))
          |> or_fail_with(
            "Expected the response of api_endpoints.echo_accept_encoding",
          )
        },
      ),
      it("sends GET /non-utf8-error to api_endpoints.non_utf8_error", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/non-utf8-error")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.non_utf8_error(request))
        |> or_fail_with("Expected the response of api_endpoints.non_utf8_error")
      }),
      it("sends GET /redirect/301 to api_endpoints.redirect_301", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/301")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.redirect_301(request))
        |> or_fail_with("Expected the response of api_endpoints.redirect_301")
      }),
      it("sends GET /redirect/302 to api_endpoints.redirect_302", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/302")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.redirect_302(request))
        |> or_fail_with("Expected the response of api_endpoints.redirect_302")
      }),
      it("sends GET /redirect/303 to api_endpoints.redirect_303", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/303")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.redirect_303(request))
        |> or_fail_with("Expected the response of api_endpoints.redirect_303")
      }),
      it("sends GET /redirect/307 to api_endpoints.redirect_307", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/307")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.redirect_307(request))
        |> or_fail_with("Expected the response of api_endpoints.redirect_307")
      }),
      it("sends GET /redirect/308 to api_endpoints.redirect_308", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/308")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.redirect_308(request))
        |> or_fail_with("Expected the response of api_endpoints.redirect_308")
      }),
      it("sends GET /redirect/chain to api_endpoints.redirect_chain", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/chain")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.redirect_chain(request))
        |> or_fail_with("Expected the response of api_endpoints.redirect_chain")
      }),
      it("sends GET /redirect/chain/2 to api_endpoints.redirect_chain_2", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/chain/2")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(api_endpoints.redirect_chain_2(request))
        |> or_fail_with(
          "Expected the response of api_endpoints.redirect_chain_2",
        )
      }),
      it(
        "sends GET /redirect/absolute to api_endpoints.redirect_absolute",
        fn() {
          // Arrange
          let request = test_request.create_request(Get, "/redirect/absolute")

          // Act
          let response = answer_request(BuiltInEndpoints, request)

          // Assert
          response
          |> should
          |> be_equal(api_endpoints.redirect_absolute(request))
          |> or_fail_with(
            "Expected the response of api_endpoints.redirect_absolute",
          )
        },
      ),
      it("sends GET /stream/fast to stream_endpoints.stream_fast", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/fast")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_fast(request))
        |> or_fail_with("Expected the response of stream_endpoints.stream_fast")
      }),
      it("sends GET /stream/slow to stream_endpoints.stream_slow", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/slow")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_slow(request))
        |> or_fail_with("Expected the response of stream_endpoints.stream_slow")
      }),
      it("sends GET /stream/burst to stream_endpoints.stream_burst", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/burst")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_burst(request))
        |> or_fail_with(
          "Expected the response of stream_endpoints.stream_burst",
        )
      }),
      it("sends GET /stream/error to stream_endpoints.stream_error", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/error")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_error(request))
        |> or_fail_with(
          "Expected the response of stream_endpoints.stream_error",
        )
      }),
      it("sends GET /stream/huge to stream_endpoints.stream_huge", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/huge")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_huge(request))
        |> or_fail_with("Expected the response of stream_endpoints.stream_huge")
      }),
      it("sends GET /stream/drop to stream_endpoints.stream_drop", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/drop")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_drop(request))
        |> or_fail_with("Expected the response of stream_endpoints.stream_drop")
      }),
      it("sends GET /stream/json to stream_endpoints.stream_json", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/json")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_json(request))
        |> or_fail_with("Expected the response of stream_endpoints.stream_json")
      }),
      it("sends GET /stream/binary to stream_endpoints.stream_binary", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/binary")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_binary(request))
        |> or_fail_with(
          "Expected the response of stream_endpoints.stream_binary",
        )
      }),
      it("sends GET /stream/gzip to stream_endpoints.stream_gzip", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/gzip")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_gzip(request))
        |> or_fail_with("Expected the response of stream_endpoints.stream_gzip")
      }),
      it("sends GET /stream/deflate to stream_endpoints.stream_deflate", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/deflate")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(stream_endpoints.stream_deflate(request))
        |> or_fail_with(
          "Expected the response of stream_endpoints.stream_deflate",
        )
      }),
      it(
        "sends GET /stream/unknown-encoding to stream_endpoints.stream_unknown_encoding",
        fn() {
          // Arrange
          let request =
            test_request.create_request(Get, "/stream/unknown-encoding")

          // Act
          let response = answer_request(BuiltInEndpoints, request)

          // Assert
          response
          |> should
          |> be_equal(stream_endpoints.stream_unknown_encoding(request))
          |> or_fail_with(
            "Expected the response of stream_endpoints.stream_unknown_encoding",
          )
        },
      ),
    ]),
    group("answer with configured routes", [
      it("sends GET requests to the configured routes", fn() {
        // Arrange
        let mode = ConfiguredRoutes([MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Get, "/x")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
      it("sends POST requests to the configured routes", fn() {
        // Arrange
        let mode = ConfiguredRoutes([MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Post, "/x")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
      it("sends PUT requests to the configured routes", fn() {
        // Arrange
        let mode = ConfiguredRoutes([MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Put, "/x")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
      it("sends DELETE requests to the configured routes", fn() {
        // Arrange
        let mode = ConfiguredRoutes([MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Delete, "/x")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
      it("sends PATCH requests to the configured routes", fn() {
        // Arrange
        let mode = ConfiguredRoutes([MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Patch, "/x")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
    ]),
    group("answer rules", [
      it("answers 404 for an unknown path and does not read the body", fn() {
        // Arrange
        let head =
          test_request.head_of(test_request.create_request(Get, "/nope"))

        // Act
        let response =
          routes.answer(BuiltInEndpoints, head, fn() {
            panic as "The body must not be read"
          })

        // Assert
        response
        |> should
        |> be_equal(routes.route_not_found_response())
        |> or_fail_with("Expected 404 without a body read")
      }),
      it("answers 400 when the body cannot be read", fn() {
        // Arrange
        let head =
          test_request.head_of(test_request.create_request(Post, "/post"))

        // Act
        let response =
          routes.answer(BuiltInEndpoints, head, fn() { Error(Nil) })

        // Assert
        response
        |> should
        |> be_equal(routes.bad_request_response())
        |> or_fail_with("Expected 400 with an empty body")
      }),
      it("answers 404 for a method that has no route on the path", fn() {
        // Arrange
        let request = test_request.create_request(Post, "/text")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(routes.route_not_found_response())
        |> or_fail_with("Expected 404 for POST /text")
      }),
      it("answers 404 for HEAD", fn() {
        // Arrange
        let request = test_request.create_request(Head, "/text")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(routes.route_not_found_response())
        |> or_fail_with("Expected 404 for HEAD /text")
      }),
      it("answers 404 for TRACE", fn() {
        // Arrange
        let request = test_request.create_request(Trace, "/text")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(routes.route_not_found_response())
        |> or_fail_with("Expected 404 for TRACE /text")
      }),
      it("answers 404 for CONNECT", fn() {
        // Arrange
        let request = test_request.create_request(Connect, "/text")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(routes.route_not_found_response())
        |> or_fail_with("Expected 404 for CONNECT /text")
      }),
      it("answers 404 for a method that is not standard", fn() {
        // Arrange
        let request = test_request.create_request(Other("PURGE"), "/text")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(routes.route_not_found_response())
        |> or_fail_with("Expected 404 for PURGE /text")
      }),
      it("matches a path with a file extension on a literal segment", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/text.json")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "Hello, World!"))
        |> or_fail_with("Expected the GET /text response")
      }),
      it("ignores empty path segments", fn() {
        // Arrange
        let request = test_request.create_request(Get, "//text/")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "Hello, World!"))
        |> or_fail_with("Expected the GET /text response")
      }),
      it("answers 404 for a path with more segments than the route", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/chain/2/3")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(routes.route_not_found_response())
        |> or_fail_with("Expected 404 for an extra segment")
      }),
      it("answers 404 for a path with fewer segments than the route", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/status")

        // Act
        let response = answer_request(BuiltInEndpoints, request)

        // Assert
        response
        |> should
        |> be_equal(routes.route_not_found_response())
        |> or_fail_with("Expected 404 without the code segment")
      }),
    ]),
    group("answer rules in config mode", [
      it("sends HEAD to the configured routes", fn() {
        // Arrange
        let mode = ConfiguredRoutes([MockRoute("/x", Prefix, None, 200, "x")])
        let request = test_request.create_request(Head, "/x")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the answer of the route")
      }),
      it("sends OPTIONS to the configured routes", fn() {
        // Arrange
        let mode = ConfiguredRoutes([MockRoute("/x", Prefix, None, 200, "x")])
        let request = test_request.create_request(Options, "/x")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the answer of the route")
      }),
      it("sends the root path to the configured routes", fn() {
        // Arrange
        let mode = ConfiguredRoutes([MockRoute("/", Exact, None, 200, "root")])
        let request = test_request.create_request(Get, "/")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "root"))
        |> or_fail_with("Expected the configured response")
      }),
      it("answers 404 Not found for a TRACE request to a GET route", fn() {
        // Arrange
        let mode =
          ConfiguredRoutes([MockRoute("/x", Exact, Some(Get), 200, "x")])
        let request = test_request.create_request(Trace, "/x")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(404, "Not found"))
        |> or_fail_with("Expected 404 Not found")
      }),
      it("matches a PURGE request to a route with the method PURGE", fn() {
        // Arrange
        let mode =
          ConfiguredRoutes([
            MockRoute("/x", Exact, Some(Other("PURGE")), 200, "purged"),
          ])
        let request = test_request.create_request(Other("PURGE"), "/x")

        // Act
        let response = answer_request(mode, request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "purged"))
        |> or_fail_with("Expected the PURGE route to answer")
      }),
    ]),
    group("index", [
      it("returns the page of index_view.format_index as text", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/")

        // Act
        let response = routes.index(request)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, index_view.format_index()))
        |> or_fail_with("Expected 200 with the index page")
      }),
    ]),
    group("find_endpoint with the built-in endpoint table", [
      it("finds an endpoint for every entry of the table", fn() {
        // Arrange
        let table = built_in_endpoints.table()

        // Act
        let unanswered_lines =
          table
          |> list.filter(fn(built_in_endpoint) {
            routes.find_endpoint(
              BuiltInEndpoints,
              built_in_endpoint.method,
              request_path(built_in_endpoint.pattern),
            )
            |> result.is_error
          })
          |> list.map(built_in_endpoints.request_line)

        // Assert
        unanswered_lines
        |> should
        |> be_equal([])
        |> or_fail_with("Expected an endpoint for every entry of the table")
      }),
    ]),
  ])
}

/// A request path that matches a path pattern: `200` for each parameter.
fn request_path(pattern: List(Segment)) -> String {
  pattern
  |> list.map(fn(segment) {
    case segment {
      Literal(name) -> name
      Parameter(_name) -> "200"
    }
  })
  |> string.join("/")
  |> string.append("/", _)
}
