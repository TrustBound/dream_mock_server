import dream_mock_server/internal/message.{
  Bytes, Request, RequestHead, Response, Stream,
}
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/request as test_request
import gleam/http.{Get, Post}
import gleam/option.{Some}
import gleam/yielder

pub fn tests() -> TestSuite {
  describe("dream_mock_server/internal/message", [
    with_body_tests(),
    find_header_tests(),
    response_tests(),
  ])
}

fn with_body_tests() {
  group("with_body", [
    it("adds the body to the fields of the head", fn() {
      // Arrange
      let head =
        RequestHead(method: Post, path: "/post", query: Some("a=1"), headers: [
          #("host", "localhost"),
        ])

      // Act
      let request = message.with_body(head, <<"hi":utf8>>)

      // Assert
      request
      |> should
      |> be_equal(
        Request(
          method: Post,
          path: "/post",
          query: Some("a=1"),
          headers: [#("host", "localhost")],
          body: <<"hi":utf8>>,
        ),
      )
      |> or_fail_with("Expected the head fields and the body")
    }),
  ])
}

fn find_header_tests() {
  group("find_header", [
    it("finds a header with a name in another case", fn() {
      // Arrange
      let request =
        Request(..test_request.create_request(Get, "/"), headers: [
          #("Accept-Encoding", "gzip"),
        ])

      // Act
      let value = message.find_header(request, "accept-encoding")

      // Assert
      value
      |> should
      |> be_equal(Ok("gzip"))
      |> or_fail_with("Expected the header value")
    }),
    it("returns Error(Nil) when the request has no such header", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/")

      // Act
      let value = message.find_header(request, "accept-encoding")

      // Assert
      value
      |> should
      |> be_equal(Error(Nil))
      |> or_fail_with("Expected Error(Nil)")
    }),
  ])
}

fn response_tests() {
  group("responses", [
    it("text_response sets the UTF-8 text content type", fn() {
      // Arrange
      let body = "hello"

      // Act
      let response = message.text_response(201, body)

      // Assert
      response
      |> should
      |> be_equal(Response(
        status: 201,
        headers: [#("content-type", "text/plain; charset=utf-8")],
        body: Bytes(<<"hello":utf8>>),
      ))
      |> or_fail_with("Expected a UTF-8 text response")
    }),
    it("json_response sets the UTF-8 JSON content type", fn() {
      // Arrange
      let body = "{}"

      // Act
      let response = message.json_response(200, body)

      // Assert
      response
      |> should
      |> be_equal(Response(
        status: 200,
        headers: [#("content-type", "application/json; charset=utf-8")],
        body: Bytes(<<"{}":utf8>>),
      ))
      |> or_fail_with("Expected a UTF-8 JSON response")
    }),
    it("stream_response sets the given content type", fn() {
      // Arrange
      let chunks = yielder.from_list([<<"a":utf8>>])

      // Act
      let response = message.stream_response(200, chunks, "text/plain")

      // Assert
      response
      |> should
      |> be_equal(Response(
        status: 200,
        headers: [#("content-type", "text/plain")],
        body: Stream(chunks),
      ))
      |> or_fail_with("Expected a text/plain stream")
    }),
  ])
}
