//// Tests for the guide "Stand in for a third-party API"
//// (docs/guides/stand-in-for-an-api.md). Each test starts a config mode
//// server. A test of an output block compares the real answers with the
//// output file that the guide shows; the other tests assert the exact
//// answer that the guide's text gives.

import dream_mock_server/config.{type MockRoute}
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/output_file
import gleam/http.{type Method}
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import snippets/config_mode_method_specific
import snippets/config_mode_ordering
import snippets/guide_stand_in_ask.{type ChatError, ApiError, ask}
import snippets/guide_stand_in_routes

pub fn tests() -> TestSuite {
  describe("stand-in guide", [
    it("step 2: ask gets the reply of the chat routes", fn() {
      // Arrange
      let assert Ok(stand_in) =
        server.start_with_config(19_876, guide_stand_in_routes.chat_routes())

      // Act
      let answer = ask("http://localhost:19876", "test-key", "Say hello")
      server.stop(stand_in)

      // Assert
      Ok(
        "server.start_with_config(19876, chat_routes())\n"
        <> "ask(\"http://localhost:19876\", \"test-key\", \"Say hello\")\n"
        <> "  -> "
        <> answer_literal(answer)
        <> "\n",
      )
      |> should
      |> be_equal(output_file.read("guide_stand_in_ask"))
      |> or_fail_with("Expected the reply of the output file")
    }),
    it("step 3: the failing routes give the errors of the guide", fn() {
      // Arrange
      let server_error_routes = [
        config.MockRoute(
          path: "/v1/chat/completions",
          path_match: config.Exact,
          method: option.Some(http.Post),
          status: 500,
          body: "{\"error\":{\"message\":\"Internal error\"}}",
        ),
      ]

      // Act
      let rows = [
        #(
          "ask against rate_limited_routes()",
          ask_with_routes(19_877, guide_stand_in_routes.rate_limited_routes()),
        ),
        #(
          "ask against broken_routes()",
          ask_with_routes(19_878, guide_stand_in_routes.broken_routes()),
        ),
        #(
          "ask against a 500 route",
          ask_with_routes(19_861, server_error_routes),
        ),
      ]

      // Assert
      Ok(output_file.table(rows))
      |> should
      |> be_equal(output_file.read("guide_stand_in_failing_routes"))
      |> or_fail_with("Expected the errors of the output file")
    }),
    it("step 4: GET /resource gives 200", fn() {
      // Act
      let answer =
        send_with_routes(
          19_862,
          config_mode_method_specific.resource_routes(),
          http.Get,
          "/resource",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(200, "{\"ok\":true}")))
      |> or_fail_with("Expected 200 for GET")
    }),
    it("step 4: POST /resource gives 201", fn() {
      // Act
      let answer =
        send_with_routes(
          19_863,
          config_mode_method_specific.resource_routes(),
          http.Post,
          "/resource",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(201, "{\"created\":true}")))
      |> or_fail_with("Expected 201 for POST")
    }),
    it("step 4: DELETE /resource gives 404 Not found", fn() {
      // Act
      let answer =
        send_with_routes(
          19_864,
          config_mode_method_specific.resource_routes(),
          http.Delete,
          "/resource",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(404, "Not found")))
      |> or_fail_with("Expected 404 for a method with no route")
    }),
    it("step 4: the exact route comes before the prefix route", fn() {
      // Arrange
      let assert Ok(stand_in) =
        server.start_with_config(19_865, config_mode_ordering.api_routes())

      // Act
      let rows =
        list.map(
          ["/api/special", "/api/users", "/apiary", "/api/special?debug=1"],
          fn(path) {
            #("GET " <> path, send(19_865, http.Get, path) |> status_and_body)
          },
        )
      server.stop(stand_in)

      // Assert
      Ok(output_file.table(rows))
      |> should
      |> be_equal(output_file.read("guide_stand_in_route_order"))
      |> or_fail_with("Expected the answers of the output file")
    }),
    it("step 4: an exact route does not match a trailing slash", fn() {
      // Act
      let answer =
        send_with_routes(
          19_869,
          config_mode_method_specific.resource_routes(),
          http.Get,
          "/resource/",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(404, "Not found")))
      |> or_fail_with("Expected no match for /resource/")
    }),
    it("step 4: a GET to a POST route gives 404 Not found", fn() {
      // Act
      let answer =
        send_with_routes(
          19_870,
          guide_stand_in_routes.chat_routes(),
          http.Get,
          "/v1/chat/completions",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(404, "Not found")))
      |> or_fail_with("Expected 404 for GET")
    }),
    it("routes: an OPTIONS request reaches the routes", fn() {
      // Act
      let answer =
        send_with_routes(
          19_871,
          config_mode_ordering.api_routes(),
          http.Options,
          "/api/special",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(200, "special")))
      |> or_fail_with("Expected the answer of the /api/special route")
    }),
    it("limits: every route answers with the text/plain content type", fn() {
      // Arrange
      let assert Ok(stand_in) =
        server.start_with_config(19_872, guide_stand_in_routes.chat_routes())
      let assert Ok(http_request) =
        request.to("http://localhost:19872/v1/chat/completions")

      // Act
      let content_type =
        http_request
        |> request.set_method(http.Post)
        |> httpc.send
        |> result.replace_error(Nil)
        |> result.try(fn(response) {
          response_header(response.headers, "content-type")
        })
      server.stop(stand_in)

      // Assert
      content_type
      |> should
      |> be_equal(Ok("text/plain; charset=utf-8"))
      |> or_fail_with("Expected text/plain for a JSON body")
    }),
    it("limits: a request without authorization gets the answer", fn() {
      // Arrange
      let assert [route] = guide_stand_in_routes.chat_routes()

      // Act
      let answer =
        send_with_routes(
          19_873,
          guide_stand_in_routes.chat_routes(),
          http.Post,
          "/v1/chat/completions",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(200, route.body)))
      |> or_fail_with("Expected the answer without any header check")
    }),
    it("limits: a config mode server has no built-in endpoints", fn() {
      // Act
      let answer =
        send_with_routes(
          19_874,
          config_mode_ordering.api_routes(),
          http.Get,
          "/text",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(404, "Not found")))
      |> or_fail_with("Expected 404 Not found for /text")
    }),
  ])
}

fn send_with_routes(
  port: Int,
  routes: List(MockRoute),
  method: Method,
  path: String,
) -> Result(#(Int, String), String) {
  let assert Ok(stand_in) = server.start_with_config(port, routes)
  let answer = send(port, method, path)
  server.stop(stand_in)
  answer
}

fn send(
  port: Int,
  method: Method,
  path: String,
) -> Result(#(Int, String), String) {
  request.to("http://localhost:" <> int.to_string(port) <> path)
  |> result.replace_error("Not a valid URL")
  |> result.map(request.set_method(_, method))
  |> result.try(fn(http_request) {
    httpc.send(http_request) |> result.map_error(string.inspect)
  })
  |> result.map(fn(response) { #(response.status, response.body) })
}

/// Writes an answer as the guide does: the status and the body as a string.
fn status_and_body(answer: Result(#(Int, String), String)) -> String {
  case answer {
    Ok(#(status, body)) -> int.to_string(status) <> " " <> string.inspect(body)
    Error(message) -> message
  }
}

/// Starts a stand-in with `routes`, asks it, stops it, and writes the
/// answer as Gleam code.
fn ask_with_routes(port: Int, routes: List(MockRoute)) -> String {
  let assert Ok(stand_in) = server.start_with_config(port, routes)
  let answer =
    ask("http://localhost:" <> int.to_string(port), "test-key", "Say hello")
  server.stop(stand_in)
  answer_literal(answer)
}

/// Writes an answer of `ask` as Gleam code, with the labels of the fields
/// of `ApiError`.
fn answer_literal(answer: Result(String, ChatError)) -> String {
  case answer {
    Ok(reply) -> "Ok(" <> string.inspect(reply) <> ")"
    Error(ApiError(status:, body:)) ->
      "Error(ApiError(status: "
      <> int.to_string(status)
      <> ", body: "
      <> string.inspect(body)
      <> "))"
    Error(other_error) -> "Error(" <> string.inspect(other_error) <> ")"
  }
}

fn response_header(
  headers: List(#(String, String)),
  name: String,
) -> Result(String, Nil) {
  case headers {
    [] -> Error(Nil)
    [#(header_name, value), ..] if header_name == name -> Ok(value)
    [_other, ..rest] -> response_header(rest, name)
  }
}
