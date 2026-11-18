import dream/context.{EmptyContext}
import dream/dream
import dream/http/request.{Delete, Get, Patch, Post, Put}
import dream/http/response.{json_response, text_response}
import dream/router.{EmptyServices}
import dream_mock_server/config.{Exact, MockConfigContext, MockRoute}
import dream_mock_server/controllers/api_controller
import dream_mock_server/controllers/stream_controller
import dream_mock_server/router.{create_config_router, create_router} as _mock_router
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/types.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/request as test_request
import gleam/option.{None}

pub fn tests() -> TestSuite(Nil) {
  describe("dream_mock_server/router", [
    group("create_router", [
      it("sends GET / to stream_controller.index", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.index(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with("Expected the response of stream_controller.index")
      }),
      it("sends GET /get to api_controller.get", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/get")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.get(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.get")
      }),
      it("sends POST /post to api_controller.post", fn() {
        // Arrange
        let request = test_request.create_request(Post, "/post")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.post(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.post")
      }),
      it("sends POST /content-type to api_controller.content_type", fn() {
        // Arrange
        let request = test_request.create_request(Post, "/content-type")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.content_type(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with("Expected the response of api_controller.content_type")
      }),
      it("sends PUT /put to api_controller.put", fn() {
        // Arrange
        let request = test_request.create_request(Put, "/put")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.put(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.put")
      }),
      it("sends PATCH /patch to api_controller.patch", fn() {
        // Arrange
        let request = test_request.create_request(Patch, "/patch")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.patch(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.patch")
      }),
      it("sends DELETE /delete to api_controller.delete", fn() {
        // Arrange
        let request = test_request.create_request(Delete, "/delete")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.delete(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.delete")
      }),
      it("sends GET /json to api_controller.json_endpoint", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/json")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.json_endpoint(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with("Expected the response of api_controller.json_endpoint")
      }),
      it("sends GET /text to api_controller.text", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/text")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.text(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.text")
      }),
      it("sends GET /uuid to api_controller.uuid", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/uuid")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.uuid(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.uuid")
      }),
      it("sends GET /status/:code to api_controller.status", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/status/418")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(json_response(418, "{\"status\":418}"))
        |> or_fail_with("Expected 418 with the status JSON")
      }),
      it("sends GET /large to api_controller.large", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/large")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.large(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.large")
      }),
      it("sends GET /empty to api_controller.empty", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/empty")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.empty(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.empty")
      }),
      it("sends GET /slow to the slow endpoint", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/slow")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "Slow response"))
        |> or_fail_with("Expected the slow response")
      }),
      it("sends GET /gzip to api_controller.gzip", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/gzip")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.gzip(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.gzip")
      }),
      it("sends GET /deflate to api_controller.deflate", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/deflate")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.deflate(request, EmptyContext, EmptyServices))
        |> or_fail_with("Expected the response of api_controller.deflate")
      }),
      it("sends GET /identity to api_controller.identity", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/identity")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.identity(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with("Expected the response of api_controller.identity")
      }),
      it("sends GET /unknown-encoding to api_controller.unknown_encoding", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/unknown-encoding")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.unknown_encoding(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of api_controller.unknown_encoding",
        )
      }),
      it("sends GET /corrupted-gzip to api_controller.corrupted_gzip", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/corrupted-gzip")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.corrupted_gzip(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of api_controller.corrupted_gzip",
        )
      }),
      it(
        "sends GET /echo-accept-encoding to api_controller.echo_accept_encoding",
        fn() {
          // Arrange
          let request =
            test_request.create_request(Get, "/echo-accept-encoding")

          // Act
          let response =
            dream.route_request(
              create_router(),
              request,
              EmptyContext,
              EmptyServices,
            )

          // Assert
          response
          |> should
          |> be_equal(api_controller.echo_accept_encoding(
            request,
            EmptyContext,
            EmptyServices,
          ))
          |> or_fail_with(
            "Expected the response of api_controller.echo_accept_encoding",
          )
        },
      ),
      it("sends GET /non-utf8-error to api_controller.non_utf8_error", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/non-utf8-error")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.non_utf8_error(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of api_controller.non_utf8_error",
        )
      }),
      it("sends GET /redirect/301 to api_controller.redirect_301", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/301")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.redirect_301(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with("Expected the response of api_controller.redirect_301")
      }),
      it("sends GET /redirect/302 to api_controller.redirect_302", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/302")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.redirect_302(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with("Expected the response of api_controller.redirect_302")
      }),
      it("sends GET /redirect/303 to api_controller.redirect_303", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/303")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.redirect_303(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with("Expected the response of api_controller.redirect_303")
      }),
      it("sends GET /redirect/307 to api_controller.redirect_307", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/307")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.redirect_307(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with("Expected the response of api_controller.redirect_307")
      }),
      it("sends GET /redirect/308 to api_controller.redirect_308", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/308")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.redirect_308(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with("Expected the response of api_controller.redirect_308")
      }),
      it("sends GET /redirect/chain to api_controller.redirect_chain", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/chain")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.redirect_chain(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of api_controller.redirect_chain",
        )
      }),
      it("sends GET /redirect/chain/2 to api_controller.redirect_chain_2", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/redirect/chain/2")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(api_controller.redirect_chain_2(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of api_controller.redirect_chain_2",
        )
      }),
      it(
        "sends GET /redirect/absolute to api_controller.redirect_absolute",
        fn() {
          // Arrange
          let request = test_request.create_request(Get, "/redirect/absolute")

          // Act
          let response =
            dream.route_request(
              create_router(),
              request,
              EmptyContext,
              EmptyServices,
            )

          // Assert
          response
          |> should
          |> be_equal(api_controller.redirect_absolute(
            request,
            EmptyContext,
            EmptyServices,
          ))
          |> or_fail_with(
            "Expected the response of api_controller.redirect_absolute",
          )
        },
      ),
      it("sends GET /stream/fast to stream_controller.stream_fast", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/fast")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_fast(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_fast",
        )
      }),
      it("sends GET /stream/slow to stream_controller.stream_slow", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/slow")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_slow(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_slow",
        )
      }),
      it("sends GET /stream/burst to stream_controller.stream_burst", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/burst")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_burst(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_burst",
        )
      }),
      it("sends GET /stream/error to stream_controller.stream_error", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/error")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_error(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_error",
        )
      }),
      it("sends GET /stream/huge to stream_controller.stream_huge", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/huge")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_huge(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_huge",
        )
      }),
      it("sends GET /stream/drop to stream_controller.stream_drop", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/drop")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_drop(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_drop",
        )
      }),
      it("sends GET /stream/json to stream_controller.stream_json", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/json")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_json(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_json",
        )
      }),
      it("sends GET /stream/binary to stream_controller.stream_binary", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/binary")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_binary(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_binary",
        )
      }),
      it("sends GET /stream/gzip to stream_controller.stream_gzip", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/gzip")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_gzip(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_gzip",
        )
      }),
      it("sends GET /stream/deflate to stream_controller.stream_deflate", fn() {
        // Arrange
        let request = test_request.create_request(Get, "/stream/deflate")

        // Act
        let response =
          dream.route_request(
            create_router(),
            request,
            EmptyContext,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(stream_controller.stream_deflate(
          request,
          EmptyContext,
          EmptyServices,
        ))
        |> or_fail_with(
          "Expected the response of stream_controller.stream_deflate",
        )
      }),
      it(
        "sends GET /stream/unknown-encoding to stream_controller.stream_unknown_encoding",
        fn() {
          // Arrange
          let request =
            test_request.create_request(Get, "/stream/unknown-encoding")

          // Act
          let response =
            dream.route_request(
              create_router(),
              request,
              EmptyContext,
              EmptyServices,
            )

          // Assert
          response
          |> should
          |> be_equal(stream_controller.stream_unknown_encoding(
            request,
            EmptyContext,
            EmptyServices,
          ))
          |> or_fail_with(
            "Expected the response of stream_controller.stream_unknown_encoding",
          )
        },
      ),
    ]),
    group("create_config_router", [
      it("sends GET requests to the configured routes", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Get, "/x")

        // Act
        let response =
          dream.route_request(
            create_config_router(),
            request,
            context,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
      it("sends POST requests to the configured routes", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Post, "/x")

        // Act
        let response =
          dream.route_request(
            create_config_router(),
            request,
            context,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
      it("sends PUT requests to the configured routes", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Put, "/x")

        // Act
        let response =
          dream.route_request(
            create_config_router(),
            request,
            context,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
      it("sends DELETE requests to the configured routes", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Delete, "/x")

        // Act
        let response =
          dream.route_request(
            create_config_router(),
            request,
            context,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
      it("sends PATCH requests to the configured routes", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [MockRoute("/x", Exact, None, 200, "x")])
        let request = test_request.create_request(Patch, "/x")

        // Act
        let response =
          dream.route_request(
            create_config_router(),
            request,
            context,
            EmptyServices,
          )

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "x"))
        |> or_fail_with("Expected the configured response")
      }),
    ]),
  ])
}
