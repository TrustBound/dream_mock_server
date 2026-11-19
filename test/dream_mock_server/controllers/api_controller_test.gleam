import dream/context.{EmptyContext}
import dream/http/header.{Header}
import dream/http/request.{Bytes, Delete, Get, Patch, Post, Put, Request, Text}
import dream/http/response.{Response, json_response, text_response}
import dream/router.{EmptyServices}
import dream_mock_server/compression
import dream_mock_server/controllers/api_controller
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/types.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/request as test_request
import fixtures/response.{create_redirect_response} as _test_response
import gleam/option.{Some}
import gleam/string

pub fn tests() -> TestSuite(Nil) {
  describe("dream_mock_server/controllers/api_controller", [
    get_tests(),
    post_tests(),
    put_tests(),
    patch_tests(),
    delete_tests(),
    status_tests(),
    simple_endpoint_tests(),
    content_type_tests(),
    compression_endpoint_tests(),
    raw_body_endpoint_tests(),
    echo_accept_encoding_tests(),
    redirect_tests(),
  ])
}

fn get_tests() {
  group("get", [
    it("returns the path and query as JSON", fn() {
      // Arrange
      let request =
        Request(..test_request.create_request(Get, "/get"), query: "a=1")

      // Act
      let response = api_controller.get(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        200,
        "{\"method\":\"GET\",\"url\":\"/get\",\"query\":\"a=1\",\"headers\":[]}",
      ))
      |> or_fail_with("Expected 200 with the GET echo JSON")
    }),
  ])
}

fn post_tests() {
  group("post", [
    it("returns 201 with the text body echoed as JSON", fn() {
      // Arrange
      let request =
        Request(..test_request.create_request(Post, "/post"), body: Text("hi"))

      // Act
      let response = api_controller.post(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        201,
        "{\"method\":\"POST\",\"url\":\"/post\",\"data\":\"hi\"}",
      ))
      |> or_fail_with("Expected 201 with the POST echo JSON")
    }),
    it("returns 400 when the body is not UTF-8 text", fn() {
      // Arrange
      let request =
        Request(
          ..test_request.create_request(Post, "/post"),
          body: Bytes(<<255, 254>>),
        )

      // Act
      let response = api_controller.post(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        400,
        "{\"error\":\"Request body is not UTF-8 text\"}",
      ))
      |> or_fail_with("Expected 400 for a body that is not UTF-8")
    }),
  ])
}

fn put_tests() {
  group("put", [
    it("returns 200 with the text body echoed as JSON", fn() {
      // Arrange
      let request =
        Request(..test_request.create_request(Put, "/put"), body: Text("hi"))

      // Act
      let response = api_controller.put(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        200,
        "{\"method\":\"PUT\",\"url\":\"/put\",\"data\":\"hi\"}",
      ))
      |> or_fail_with("Expected 200 with the PUT echo JSON")
    }),
    it("returns 400 when the body is not UTF-8 text", fn() {
      // Arrange
      let request =
        Request(
          ..test_request.create_request(Put, "/put"),
          body: Bytes(<<255, 254>>),
        )

      // Act
      let response = api_controller.put(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        400,
        "{\"error\":\"Request body is not UTF-8 text\"}",
      ))
      |> or_fail_with("Expected 400 for a body that is not UTF-8")
    }),
  ])
}

fn patch_tests() {
  group("patch", [
    it("returns 200 with the text body echoed as JSON", fn() {
      // Arrange
      let request =
        Request(
          ..test_request.create_request(Patch, "/patch"),
          body: Text("hi"),
        )

      // Act
      let response = api_controller.patch(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        200,
        "{\"method\":\"PATCH\",\"url\":\"/patch\",\"data\":\"hi\"}",
      ))
      |> or_fail_with("Expected 200 with the PATCH echo JSON")
    }),
    it("returns 400 when the body is not UTF-8 text", fn() {
      // Arrange
      let request =
        Request(
          ..test_request.create_request(Patch, "/patch"),
          body: Bytes(<<255, 254>>),
        )

      // Act
      let response = api_controller.patch(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        400,
        "{\"error\":\"Request body is not UTF-8 text\"}",
      ))
      |> or_fail_with("Expected 400 for a body that is not UTF-8")
    }),
  ])
}

fn delete_tests() {
  group("delete", [
    it("returns 200 with the method and path as JSON", fn() {
      // Arrange
      let request = test_request.create_request(Delete, "/delete")

      // Act
      let response = api_controller.delete(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        200,
        "{\"method\":\"DELETE\",\"url\":\"/delete\"}",
      ))
      |> or_fail_with("Expected 200 with the DELETE JSON")
    }),
  ])
}

fn status_tests() {
  group("status", [
    it("returns the status code of the code parameter", fn() {
      // Arrange
      let request =
        Request(..test_request.create_request(Get, "/status/418"), params: [
          #("code", "418"),
        ])

      // Act
      let response = api_controller.status(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(418, "{\"status\":418}"))
      |> or_fail_with("Expected 418 with the status JSON")
    }),
    it("returns 400 when the code parameter is not an integer", fn() {
      // Arrange
      let request =
        Request(..test_request.create_request(Get, "/status/abc"), params: [
          #("code", "abc"),
        ])

      // Act
      let response = api_controller.status(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(400, "{\"error\":\"code must be an integer\"}"))
      |> or_fail_with("Expected 400 for a code that is not an integer")
    }),
    it("returns 400 when the code parameter is missing", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/status")

      // Act
      let response = api_controller.status(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(400, "{\"error\":\"Missing code parameter\"}"))
      |> or_fail_with("Expected 400 for a missing code")
    }),
  ])
}

fn simple_endpoint_tests() {
  group("simple endpoints", [
    it("json_endpoint returns the simple JSON object", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/json")

      // Act
      let response =
        api_controller.json_endpoint(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        200,
        "{\"message\":\"Hello, World!\",\"success\":true}",
      ))
      |> or_fail_with("Expected 200 with the simple JSON")
    }),
    it("text returns Hello, World! as plain text", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/text")

      // Act
      let response = api_controller.text(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(text_response(200, "Hello, World!"))
      |> or_fail_with("Expected 200 with Hello, World!")
    }),
    it("uuid returns the fixed UUID as JSON", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/uuid")

      // Act
      let response = api_controller.uuid(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(
        200,
        "{\"uuid\":\"123e4567-e89b-12d3-a456-426614174000\"}",
      ))
      |> or_fail_with("Expected 200 with the UUID JSON")
    }),
    it("large returns 20,000 copies of one line", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/large")
      let line = "This is a repeated line to create a large response body.\n"

      // Act
      let response = api_controller.large(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(text_response(200, string.repeat(line, 20_000)))
      |> or_fail_with("Expected 200 with the large body")
    }),
    it("empty returns an empty text body", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/empty")

      // Act
      let response = api_controller.empty(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(text_response(200, ""))
      |> or_fail_with("Expected 200 with an empty body")
    }),
    it("slow returns Slow response after its delay", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/slow")

      // Act
      let response = api_controller.slow(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(text_response(200, "Slow response"))
      |> or_fail_with("Expected 200 with Slow response")
    }),
  ])
}

fn content_type_tests() {
  group("content_type", [
    it("returns the Content-Type of the request", fn() {
      // Arrange
      let request =
        Request(
          ..test_request.create_request(Post, "/content-type"),
          content_type: Some("application/xml"),
        )

      // Act
      let response =
        api_controller.content_type(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(text_response(200, "application/xml"))
      |> or_fail_with("Expected 200 with the request Content-Type")
    }),
    it("returns an empty body when the request has no Content-Type", fn() {
      // Arrange
      let request = test_request.create_request(Post, "/content-type")

      // Act
      let response =
        api_controller.content_type(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(text_response(200, ""))
      |> or_fail_with("Expected 200 with an empty body")
    }),
  ])
}

fn compression_endpoint_tests() {
  group("compression endpoints", [
    it("gzip returns Hello, World! gzip-compressed", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/gzip")

      // Act
      let response = api_controller.gzip(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(Response(
        status: 200,
        body: response.Bytes(
          compression.gzip_compress(<<"Hello, World!":utf8>>),
        ),
        headers: [
          Header("Content-Type", "text/plain"),
          Header("Content-Encoding", "gzip"),
        ],
        cookies: [],
        content_type: Some("text/plain"),
      ))
      |> or_fail_with("Expected the gzip response")
    }),
    it("deflate returns Hello, World! deflate-compressed", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/deflate")

      // Act
      let response =
        api_controller.deflate(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(Response(
        status: 200,
        body: response.Bytes(
          compression.deflate_compress(<<"Hello, World!":utf8>>),
        ),
        headers: [
          Header("Content-Type", "text/plain"),
          Header("Content-Encoding", "deflate"),
        ],
        cookies: [],
        content_type: Some("text/plain"),
      ))
      |> or_fail_with("Expected the deflate response")
    }),
    it("identity returns plain text with Content-Encoding identity", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/identity")

      // Act
      let response =
        api_controller.identity(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(Response(
        status: 200,
        body: response.Text("Hello, World!"),
        headers: [
          Header("Content-Type", "text/plain; charset=utf-8"),
          Header("Content-Encoding", "identity"),
        ],
        cookies: [],
        content_type: Some("text/plain; charset=utf-8"),
      ))
      |> or_fail_with("Expected the identity response")
    }),
    it("unknown_encoding returns raw text with Content-Encoding br", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/unknown-encoding")

      // Act
      let response =
        api_controller.unknown_encoding(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(Response(
        status: 200,
        body: response.Text("raw-uncompressed-bytes"),
        headers: [
          Header("Content-Type", "text/plain; charset=utf-8"),
          Header("Content-Encoding", "br"),
        ],
        cookies: [],
        content_type: Some("text/plain; charset=utf-8"),
      ))
      |> or_fail_with("Expected the br response")
    }),
    it("corrupted_gzip returns bytes that are not gzip", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/corrupted-gzip")

      // Act
      let response =
        api_controller.corrupted_gzip(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(Response(
        status: 200,
        body: response.Bytes(<<"this is not valid gzip data at all":utf8>>),
        headers: [
          Header("Content-Type", "text/plain"),
          Header("Content-Encoding", "gzip"),
        ],
        cookies: [],
        content_type: Some("text/plain"),
      ))
      |> or_fail_with("Expected the corrupted gzip response")
    }),
  ])
}

fn raw_body_endpoint_tests() {
  group("non_utf8_error", [
    it("returns 400 with a body that is not UTF-8", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/non-utf8-error")

      // Act
      let response =
        api_controller.non_utf8_error(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(Response(
        status: 400,
        body: response.Bytes(<<"Error: ":utf8, 192, 193, 254, 255>>),
        headers: [Header("Content-Type", "text/plain")],
        cookies: [],
        content_type: Some("text/plain"),
      ))
      |> or_fail_with("Expected 400 with the bytes that are not UTF-8")
    }),
  ])
}

fn echo_accept_encoding_tests() {
  group("echo_accept_encoding", [
    it("returns the Accept-Encoding header of any letter case", fn() {
      // Arrange
      let request =
        Request(
          ..test_request.create_request(Get, "/echo-accept-encoding"),
          headers: [
            Header("ACCEPT-ENCODING", "gzip, deflate"),
          ],
        )

      // Act
      let response =
        api_controller.echo_accept_encoding(
          request,
          EmptyContext,
          EmptyServices,
        )

      // Assert
      response
      |> should
      |> be_equal(text_response(200, "gzip, deflate"))
      |> or_fail_with("Expected 200 with the Accept-Encoding value")
    }),
    it("returns an empty body when there is no Accept-Encoding", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/echo-accept-encoding")

      // Act
      let response =
        api_controller.echo_accept_encoding(
          request,
          EmptyContext,
          EmptyServices,
        )

      // Assert
      response
      |> should
      |> be_equal(text_response(200, ""))
      |> or_fail_with("Expected 200 with an empty body")
    }),
  ])
}

fn redirect_tests() {
  group("redirects", [
    it("redirect_301 returns 301 to /text", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/redirect/301")

      // Act
      let response =
        api_controller.redirect_301(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(create_redirect_response(301, "/text"))
      |> or_fail_with("Expected 301 to /text")
    }),
    it("redirect_302 returns 302 to /text", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/redirect/302")

      // Act
      let response =
        api_controller.redirect_302(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(create_redirect_response(302, "/text"))
      |> or_fail_with("Expected 302 to /text")
    }),
    it("redirect_303 returns 303 to /text", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/redirect/303")

      // Act
      let response =
        api_controller.redirect_303(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(create_redirect_response(303, "/text"))
      |> or_fail_with("Expected 303 to /text")
    }),
    it("redirect_307 returns 307 to /text", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/redirect/307")

      // Act
      let response =
        api_controller.redirect_307(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(create_redirect_response(307, "/text"))
      |> or_fail_with("Expected 307 to /text")
    }),
    it("redirect_308 returns 308 to /text", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/redirect/308")

      // Act
      let response =
        api_controller.redirect_308(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(create_redirect_response(308, "/text"))
      |> or_fail_with("Expected 308 to /text")
    }),
    it("redirect_chain returns 302 to /redirect/chain/2", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/redirect/chain")

      // Act
      let response =
        api_controller.redirect_chain(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(create_redirect_response(302, "/redirect/chain/2"))
      |> or_fail_with("Expected 302 to /redirect/chain/2")
    }),
    it("redirect_chain_2 returns 302 to /text", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/redirect/chain/2")

      // Act
      let response =
        api_controller.redirect_chain_2(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(create_redirect_response(302, "/text"))
      |> or_fail_with("Expected 302 to /text")
    }),
    it("redirect_absolute returns 302 to /text on the Host header", fn() {
      // Arrange
      let request =
        Request(
          ..test_request.create_request(Get, "/redirect/absolute"),
          headers: [
            Header("Host", "example.test:8080"),
          ],
        )

      // Act
      let response =
        api_controller.redirect_absolute(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(create_redirect_response(302, "http://example.test:8080/text"))
      |> or_fail_with("Expected 302 to the Host of the request")
    }),
    it("redirect_absolute uses localhost:9876 when there is no Host", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/redirect/absolute")

      // Act
      let response =
        api_controller.redirect_absolute(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(create_redirect_response(302, "http://localhost:9876/text"))
      |> or_fail_with("Expected 302 to localhost:9876")
    }),
  ])
}
