import dream/http/request.{Get, Post}
import dream/http/response.{text_response}
import dream/router.{EmptyServices}
import dream_mock_server/config.{Exact, MockConfigContext, MockRoute, Prefix}
import dream_mock_server/controllers/config_controller
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/request as test_request
import gleam/option.{None, Some}

pub fn tests() -> TestSuite {
  describe("dream_mock_server/controllers/config_controller", [
    group("handle", [
      it("returns the route of an exact path match", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [MockRoute("/foo", Exact, None, 200, "foo")])
        let request = test_request.create_request(Get, "/foo")

        // Act
        let response = config_controller.handle(request, context, EmptyServices)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "foo"))
        |> or_fail_with("Expected 200 with foo")
      }),
      it("returns 404 for a longer path of an exact route", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [MockRoute("/foo", Exact, None, 200, "foo")])
        let request = test_request.create_request(Get, "/foo/bar")

        // Act
        let response = config_controller.handle(request, context, EmptyServices)

        // Assert
        response
        |> should
        |> be_equal(text_response(404, "Not found"))
        |> or_fail_with("Expected 404 Not found")
      }),
      it("returns the route of a prefix match", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [
            MockRoute("/api", Prefix, None, 200, "api"),
          ])
        let request = test_request.create_request(Get, "/api/v1/chat")

        // Act
        let response = config_controller.handle(request, context, EmptyServices)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "api"))
        |> or_fail_with("Expected 200 with api")
      }),
      it("returns 404 for a path outside the prefix", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [
            MockRoute("/api", Prefix, None, 200, "api"),
          ])
        let request = test_request.create_request(Get, "/other")

        // Act
        let response = config_controller.handle(request, context, EmptyServices)

        // Assert
        response
        |> should
        |> be_equal(text_response(404, "Not found"))
        |> or_fail_with("Expected 404 Not found")
      }),
      it("returns the route of a matching method", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [
            MockRoute("/r", Exact, Some(Post), 201, "created"),
          ])
        let request = test_request.create_request(Post, "/r")

        // Act
        let response = config_controller.handle(request, context, EmptyServices)

        // Assert
        response
        |> should
        |> be_equal(text_response(201, "created"))
        |> or_fail_with("Expected 201 with created")
      }),
      it("returns 404 when only the method differs", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [
            MockRoute("/r", Exact, Some(Post), 201, "created"),
          ])
        let request = test_request.create_request(Get, "/r")

        // Act
        let response = config_controller.handle(request, context, EmptyServices)

        // Assert
        response
        |> should
        |> be_equal(text_response(404, "Not found"))
        |> or_fail_with("Expected 404 Not found")
      }),
      it("returns the first matching route of the list", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [
            MockRoute("/api/special", Exact, None, 200, "special"),
            MockRoute("/api", Prefix, None, 200, "general"),
          ])
        let request = test_request.create_request(Get, "/api/special")

        // Act
        let response = config_controller.handle(request, context, EmptyServices)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "special"))
        |> or_fail_with("Expected the first route to win")
      }),
      it("returns a later route when the first does not match", fn() {
        // Arrange
        let context =
          MockConfigContext(routes: [
            MockRoute("/api/special", Exact, None, 200, "special"),
            MockRoute("/api", Prefix, None, 200, "general"),
          ])
        let request = test_request.create_request(Get, "/api/other")

        // Act
        let response = config_controller.handle(request, context, EmptyServices)

        // Assert
        response
        |> should
        |> be_equal(text_response(200, "general"))
        |> or_fail_with("Expected the prefix route")
      }),
      it("returns 404 for an empty route list", fn() {
        // Arrange
        let context = MockConfigContext(routes: [])
        let request = test_request.create_request(Get, "/anything")

        // Act
        let response = config_controller.handle(request, context, EmptyServices)

        // Assert
        response
        |> should
        |> be_equal(text_response(404, "Not found"))
        |> or_fail_with("Expected 404 Not found")
      }),
    ]),
  ])
}
