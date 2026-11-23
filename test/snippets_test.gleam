//// Tests for the code blocks in the dream_mock_server README and hexdocs.
////
//// Each test runs a snippet and checks the exact result.

import dream/context.{EmptyContext}
import dream/http/request.{Get}
import dream/http/response.{json_response}
import dream/router.{EmptyServices}
import dream_mock_server/config.{Exact, MockRoute, Prefix}
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/request as test_request
import gleam/int
import gleam/option.{None}
import matchers/read_stream_chunks.{read_stream_chunks}
import snippets/config_mode_method_specific
import snippets/config_mode_ordering
import snippets/config_mode_prefix
import snippets/http_helper
import snippets/non_streaming_technique
import snippets/own_config_server
import snippets/own_server
import snippets/port
import snippets/programmatic_control
import snippets/programmatic_mode
import snippets/release_1_1_0_config_mode
import snippets/streaming_technique

pub fn tests() -> TestSuite {
  describe("snippets", [
    programmatic_mode_tests(),
    config_mode_prefix_tests(),
    config_mode_method_specific_tests(),
    config_mode_ordering_tests(),
    programmatic_control_tests(),
    streaming_technique_tests(),
    non_streaming_technique_tests(),
    own_server_tests(),
    own_config_server_tests(),
    release_1_1_0_config_mode_tests(),
  ])
}

fn programmatic_mode_tests() {
  group("programmatic_mode.with_mock_server", [
    it("runs the test body against the server", fn() {
      // Arrange
      let port = port.free_port()

      // Act
      let outcome =
        programmatic_mode.with_mock_server(port, fn(base_url) {
          http_helper.get(base_url <> "/text")
        })

      // Assert
      outcome
      |> should
      |> be_equal(Ok(Ok(#(200, "Hello, World!"))))
      |> or_fail_with("Expected the /text response from the test body")
    }),
  ])
}

fn config_mode_prefix_tests() {
  group("config_mode_prefix", [
    it("chat_completion_routes returns one prefix route", fn() {
      // Act
      let routes = config_mode_prefix.chat_completion_routes()

      // Assert
      routes
      |> should
      |> be_equal([
        MockRoute(
          path: "/v1/chat/completions",
          path_match: Prefix,
          method: None,
          status: 200,
          body: "{\"choices\":[{\"message\":{\"content\":\"\"}}]}",
        ),
      ])
      |> or_fail_with("Expected one prefix route")
    }),
    it("start_chat_mock matches a longer path by prefix", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = config_mode_prefix.start_chat_mock(port)

      // Act
      let response =
        http_helper.get(
          "http://localhost:"
          <> int.to_string(port)
          <> "/v1/chat/completions/stream",
        )
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(
        Ok(#(200, "{\"choices\":[{\"message\":{\"content\":\"\"}}]}")),
      )
      |> or_fail_with("Expected the chat completion body")
    }),
  ])
}

fn config_mode_method_specific_tests() {
  group("config_mode_method_specific.resource_routes", [
    it("answers GET with 200", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) =
        server.start_with_config(
          port,
          config_mode_method_specific.resource_routes(),
        )

      // Act
      let response =
        http_helper.get(
          "http://localhost:" <> int.to_string(port) <> "/resource",
        )
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "{\"ok\":true}")))
      |> or_fail_with("Expected 200 for GET")
    }),
    it("answers POST with 201", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) =
        server.start_with_config(
          port,
          config_mode_method_specific.resource_routes(),
        )

      // Act
      let response =
        http_helper.post(
          "http://localhost:" <> int.to_string(port) <> "/resource",
          "",
        )
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(201, "{\"created\":true}")))
      |> or_fail_with("Expected 201 for POST")
    }),
  ])
}

fn config_mode_ordering_tests() {
  group("config_mode_ordering.api_routes", [
    it("puts the exact route first", fn() {
      // Act
      let routes = config_mode_ordering.api_routes()

      // Assert
      routes
      |> should
      |> be_equal([
        MockRoute("/api/special", Exact, None, 200, "special"),
        MockRoute("/api", Prefix, None, 200, "general"),
      ])
      |> or_fail_with("Expected the exact route before the prefix route")
    }),
    it("sends the specific path to the exact route", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) =
        server.start_with_config(port, config_mode_ordering.api_routes())

      // Act
      let response =
        http_helper.get(
          "http://localhost:" <> int.to_string(port) <> "/api/special",
        )
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "special")))
      |> or_fail_with("Expected the exact route")
    }),
    it("sends other paths to the prefix route", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) =
        server.start_with_config(port, config_mode_ordering.api_routes())

      // Act
      let response =
        http_helper.get(
          "http://localhost:" <> int.to_string(port) <> "/api/other",
        )
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "general")))
      |> or_fail_with("Expected the prefix route")
    }),
  ])
}

fn programmatic_control_tests() {
  group("programmatic_control.fetch_text", [
    it("starts, uses and stops the server", fn() {
      // Arrange
      let port = port.free_port()

      // Act
      let response = programmatic_control.fetch_text(port)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "Hello, World!")))
      |> or_fail_with("Expected the /text response")
    }),
  ])
}

fn streaming_technique_tests() {
  group("streaming_technique.stream_fast", [
    it("streams ten chunks", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/stream/fast")

      // Act
      let response =
        streaming_technique.stream_fast(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> read_stream_chunks
      |> be_equal([
        <<"Chunk 1\n":utf8>>,
        <<"Chunk 2\n":utf8>>,
        <<"Chunk 3\n":utf8>>,
        <<"Chunk 4\n":utf8>>,
        <<"Chunk 5\n":utf8>>,
        <<"Chunk 6\n":utf8>>,
        <<"Chunk 7\n":utf8>>,
        <<"Chunk 8\n":utf8>>,
        <<"Chunk 9\n":utf8>>,
        <<"Chunk 10\n":utf8>>,
      ])
      |> or_fail_with("Expected ten chunks")
    }),
  ])
}

fn non_streaming_technique_tests() {
  group("non_streaming_technique.get", [
    it("returns the method and path as JSON", fn() {
      // Arrange
      let request = test_request.create_request(Get, "/get")

      // Act
      let response =
        non_streaming_technique.get(request, EmptyContext, EmptyServices)

      // Assert
      response
      |> should
      |> be_equal(json_response(200, "{\"method\":\"GET\",\"url\":\"/get\"}"))
      |> or_fail_with("Expected 200 with the method and path")
    }),
  ])
}

fn own_server_tests() {
  group("own_server.start_own_server", [
    it("serves the built-in endpoints", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = own_server.start_own_server(port)

      // Act
      let response =
        http_helper.get("http://localhost:" <> int.to_string(port) <> "/text")
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "Hello, World!")))
      |> or_fail_with("Expected the /text response")
    }),
  ])
}

fn own_config_server_tests() {
  group("own_config_server.start_own_config_server", [
    it("serves the given routes", fn() {
      // Arrange
      let port = port.free_port()
      let routes = [MockRoute("/x", Exact, None, 200, "x")]
      let assert Ok(handle) =
        own_config_server.start_own_config_server(port, routes)

      // Act
      let response =
        http_helper.get("http://localhost:" <> int.to_string(port) <> "/x")
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "x")))
      |> or_fail_with("Expected the configured response")
    }),
  ])
}

fn release_1_1_0_config_mode_tests() {
  group("release_1_1_0_config_mode", [
    it("start_chat_mock answers the chat completion path", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) = release_1_1_0_config_mode.start_chat_mock(port)

      // Act
      let response =
        http_helper.get(
          "http://localhost:" <> int.to_string(port) <> "/v1/chat/completions",
        )
      server.stop(handle)

      // Assert
      response
      |> should
      |> be_equal(
        Ok(#(200, "{\"choices\":[{\"message\":{\"content\":\"\"}}]}")),
      )
      |> or_fail_with("Expected the chat completion body")
    }),
  ])
}
