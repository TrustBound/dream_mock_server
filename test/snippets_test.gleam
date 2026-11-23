//// Tests for the code blocks in the dream_mock_server README and hexdocs.
////
//// Each test runs a snippet and checks the exact result.

import dream_mock_server/config.{Exact, MockRoute, Prefix}
import dream_mock_server/server
import dream_test/matchers.{be_equal, match_snapshot, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/http as raw_http
import fixtures/zlib
import gleam/bit_array
import gleam/int
import gleam/list
import gleam/option.{None}
import gleam/yielder
import snippets/api_view_delete
import snippets/api_view_error
import snippets/api_view_get
import snippets/api_view_patch
import snippets/api_view_post
import snippets/api_view_put
import snippets/api_view_simple_json
import snippets/api_view_status
import snippets/api_view_text
import snippets/api_view_uuid
import snippets/compression_deflate
import snippets/compression_deflate_chunks
import snippets/compression_gzip
import snippets/compression_gzip_chunks
import snippets/config_mode_custom_method
import snippets/config_mode_method_specific
import snippets/config_mode_ordering
import snippets/config_mode_prefix
import snippets/http_helper
import snippets/index_page
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
    config_mode_custom_method_tests(),
    config_mode_ordering_tests(),
    programmatic_control_tests(),
    streaming_technique_tests(),
    release_1_1_0_config_mode_tests(),
    compression_gzip_tests(),
    compression_deflate_tests(),
    compression_gzip_chunks_tests(),
    compression_deflate_chunks_tests(),
    api_view_tests(),
    index_page_tests(),
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

fn config_mode_custom_method_tests() {
  group("config_mode_custom_method.cache_routes", [
    it("answers PURGE with 200", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) =
        server.start_with_config(port, config_mode_custom_method.cache_routes())
      let request =
        "PURGE /cache HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

      // Act
      let answer = raw_http.raw_status_and_body(port, request)
      server.stop(handle)

      // Assert
      answer
      |> should
      |> be_equal(Ok(#("HTTP/1.1 200 OK", "purged")))
      |> or_fail_with("Expected 200 for PURGE")
    }),
    it("answers GET with 404", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) =
        server.start_with_config(port, config_mode_custom_method.cache_routes())
      let request =
        "GET /cache HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

      // Act
      let answer = raw_http.raw_status_and_body(port, request)
      server.stop(handle)

      // Assert
      answer
      |> should
      |> be_equal(Ok(#("HTTP/1.1 404 Not Found", "Not found")))
      |> or_fail_with("Expected 404 for GET")
    }),
    it("answers Purge with 404", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(handle) =
        server.start_with_config(port, config_mode_custom_method.cache_routes())
      let request =
        "Purge /cache HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n"

      // Act
      let answer = raw_http.raw_status_and_body(port, request)
      server.stop(handle)

      // Assert
      answer
      |> should
      |> be_equal(Ok(#("HTTP/1.1 404 Not Found", "Not found")))
      |> or_fail_with("Expected 404 for Purge")
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
  group("streaming_technique.fast_chunks", [
    it("gives ten chunks", fn() {
      // Arrange
      let chunks = streaming_technique.fast_chunks()

      // Act
      let chunk_list = yielder.to_list(chunks)

      // Assert
      chunk_list
      |> should
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

fn compression_gzip_tests() {
  group("compression_gzip.gzip_body", [
    it("returns gzip data that gunzips to Hello, World!", fn() {
      // Act
      let body = compression_gzip.gzip_body()

      // Assert
      zlib.gunzip(body)
      |> should
      |> be_equal(<<"Hello, World!":utf8>>)
      |> or_fail_with("Expected Hello, World! after gunzip")
    }),
  ])
}

fn compression_deflate_tests() {
  group("compression_deflate.deflate_body", [
    it("returns zlib data that inflates to Hello, World!", fn() {
      // Act
      let body = compression_deflate.deflate_body()

      // Assert
      zlib.uncompress(body)
      |> should
      |> be_equal(<<"Hello, World!":utf8>>)
      |> or_fail_with("Expected Hello, World! after inflate")
    }),
  ])
}

fn compression_gzip_chunks_tests() {
  group("compression_gzip_chunks.gzip_stream_chunks", [
    it("returns three chunks", fn() {
      // Act
      let chunks = compression_gzip_chunks.gzip_stream_chunks()

      // Assert
      list.length(chunks)
      |> should
      |> be_equal(3)
      |> or_fail_with("Expected three chunks")
    }),
    it("returns chunks that together gunzip to both text chunks", fn() {
      // Act
      let chunks = compression_gzip_chunks.gzip_stream_chunks()

      // Assert
      zlib.gunzip(bit_array.concat(chunks))
      |> should
      |> be_equal(<<"Chunk 1\nChunk 2\n":utf8>>)
      |> or_fail_with("Expected both text chunks after gunzip")
    }),
  ])
}

fn compression_deflate_chunks_tests() {
  group("compression_deflate_chunks.deflate_stream_chunks", [
    it("returns three chunks", fn() {
      // Act
      let chunks = compression_deflate_chunks.deflate_stream_chunks()

      // Assert
      list.length(chunks)
      |> should
      |> be_equal(3)
      |> or_fail_with("Expected three chunks")
    }),
    it("returns chunks that together inflate to both text chunks", fn() {
      // Act
      let chunks = compression_deflate_chunks.deflate_stream_chunks()

      // Assert
      zlib.uncompress(bit_array.concat(chunks))
      |> should
      |> be_equal(<<"Chunk 1\nChunk 2\n":utf8>>)
      |> or_fail_with("Expected both text chunks after inflate")
    }),
  ])
}

fn api_view_tests() {
  group("api_view snippets", [
    group("api_view_get.get_body", [
      it("returns the GET echo JSON", fn() {
        // Act
        let body = api_view_get.get_body()

        // Assert
        body
        |> should
        |> be_equal(
          "{\"method\":\"GET\",\"url\":\"/get\",\"query\":\"page=2\",\"headers\":[]}",
        )
        |> or_fail_with("Expected the GET echo JSON")
      }),
    ]),
    group("api_view_post.post_body", [
      it("returns the POST echo JSON", fn() {
        // Act
        let body = api_view_post.post_body()

        // Assert
        body
        |> should
        |> be_equal(
          "{\"method\":\"POST\",\"url\":\"/post\",\"data\":\"hello\"}",
        )
        |> or_fail_with("Expected the POST echo JSON")
      }),
    ]),
    group("api_view_put.put_body", [
      it("returns the PUT echo JSON", fn() {
        // Act
        let body = api_view_put.put_body()

        // Assert
        body
        |> should
        |> be_equal("{\"method\":\"PUT\",\"url\":\"/put\",\"data\":\"hello\"}")
        |> or_fail_with("Expected the PUT echo JSON")
      }),
    ]),
    group("api_view_patch.patch_body", [
      it("returns the PATCH echo JSON", fn() {
        // Act
        let body = api_view_patch.patch_body()

        // Assert
        body
        |> should
        |> be_equal(
          "{\"method\":\"PATCH\",\"url\":\"/patch\",\"data\":\"hello\"}",
        )
        |> or_fail_with("Expected the PATCH echo JSON")
      }),
    ]),
    group("api_view_delete.delete_body", [
      it("returns the DELETE echo JSON", fn() {
        // Act
        let body = api_view_delete.delete_body()

        // Assert
        body
        |> should
        |> be_equal("{\"method\":\"DELETE\",\"url\":\"/delete\"}")
        |> or_fail_with("Expected the DELETE echo JSON")
      }),
    ]),
    group("api_view_status.status_body", [
      it("returns the status JSON", fn() {
        // Act
        let body = api_view_status.status_body()

        // Assert
        body
        |> should
        |> be_equal("{\"status\":404}")
        |> or_fail_with("Expected the status JSON")
      }),
    ]),
    group("api_view_simple_json.json_body", [
      it("returns the fixed JSON object", fn() {
        // Act
        let body = api_view_simple_json.json_body()

        // Assert
        body
        |> should
        |> be_equal("{\"message\":\"Hello, World!\",\"success\":true}")
        |> or_fail_with("Expected the fixed JSON object")
      }),
    ]),
    group("api_view_uuid.uuid_body", [
      it("returns the fixed UUID JSON", fn() {
        // Act
        let body = api_view_uuid.uuid_body()

        // Assert
        body
        |> should
        |> be_equal("{\"uuid\":\"123e4567-e89b-12d3-a456-426614174000\"}")
        |> or_fail_with("Expected the fixed UUID JSON")
      }),
    ]),
    group("api_view_text.text_body", [
      it("returns the fixed text", fn() {
        // Act
        let body = api_view_text.text_body()

        // Assert
        body
        |> should
        |> be_equal("Hello, World!")
        |> or_fail_with("Expected Hello, World!")
      }),
    ]),
    group("api_view_error.error_body", [
      it("returns the error JSON", fn() {
        // Act
        let body = api_view_error.error_body()

        // Assert
        body
        |> should
        |> be_equal("{\"error\":\"code must be an integer\"}")
        |> or_fail_with("Expected the error JSON")
      }),
    ]),
  ])
}

fn index_page_tests() {
  group("index_page.index_page", [
    it("returns the info page of the snapshot", fn() {
      // Act
      let page = index_page.index_page()

      // Assert
      page
      |> should
      |> match_snapshot("test/snapshots/index_view_format_index.snap")
      |> or_fail_with("Expected the info page of the snapshot")
    }),
  ])
}
