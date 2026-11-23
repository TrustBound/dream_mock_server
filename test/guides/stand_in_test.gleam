//// Tests for the guide "Stand in for a third-party API"
//// (docs/guides/stand-in-for-an-api.md). Each test starts a config mode
//// server and asserts the exact answer that the guide shows.

import dream_mock_server/config.{type MockRoute}
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import gleam/http.{type Method}
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/option
import gleam/result
import gleam/string
import snippets/config_mode_method_specific
import snippets/config_mode_ordering
import snippets/guide_stand_in_ask.{ApiError, ask}
import snippets/guide_stand_in_routes

pub fn tests() -> TestSuite {
  describe("stand-in guide", [
    it("step 3: a 500 route gives ApiError", fn() {
      // Arrange
      let routes = [
        config.MockRoute(
          path: "/v1/chat/completions",
          path_match: config.Exact,
          method: option.Some(http.Post),
          status: 500,
          body: "{\"error\":{\"message\":\"Internal error\"}}",
        ),
      ]
      let assert Ok(stand_in) = server.start_with_config(19_861, routes)

      // Act
      let answer = ask("http://localhost:19861", "test-key", "Say hello")
      server.stop(stand_in)

      // Assert
      answer
      |> should
      |> be_equal(
        Error(ApiError(
          status: 500,
          body: "{\"error\":{\"message\":\"Internal error\"}}",
        )),
      )
      |> or_fail_with("Expected ApiError 500")
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
    it("step 4: /api/special goes to the exact route", fn() {
      // Act
      let answer =
        send_with_routes(
          19_865,
          config_mode_ordering.api_routes(),
          http.Get,
          "/api/special",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(200, "special")))
      |> or_fail_with("Expected the exact route")
    }),
    it("step 4: /api/users goes to the prefix route", fn() {
      // Act
      let answer =
        send_with_routes(
          19_866,
          config_mode_ordering.api_routes(),
          http.Get,
          "/api/users",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(200, "general")))
      |> or_fail_with("Expected the prefix route")
    }),
    it("step 4: /apiary also goes to the prefix route", fn() {
      // Act
      let answer =
        send_with_routes(
          19_867,
          config_mode_ordering.api_routes(),
          http.Get,
          "/apiary",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(200, "general")))
      |> or_fail_with("Expected the prefix /api to match /apiary")
    }),
    it("step 4: an exact route ignores the query string", fn() {
      // Act
      let answer =
        send_with_routes(
          19_868,
          config_mode_ordering.api_routes(),
          http.Get,
          "/api/special?debug=1",
        )

      // Assert
      answer
      |> should
      |> be_equal(Ok(#(200, "special")))
      |> or_fail_with("Expected the query string to be ignored")
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
    it("routes: an OPTIONS request gives 404 Route not found", fn() {
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
      |> be_equal(Ok(#(404, "Route not found")))
      |> or_fail_with("Expected 404 Route not found for OPTIONS")
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
  let answer =
    request.to("http://localhost:" <> int.to_string(port) <> path)
    |> result.replace_error("Not a valid URL")
    |> result.map(request.set_method(_, method))
    |> result.try(fn(http_request) {
      httpc.send(http_request) |> result.map_error(string.inspect)
    })
    |> result.map(fn(response) { #(response.status, response.body) })
  server.stop(stand_in)
  answer
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
