# Run the server

This guide shows the ways to run the mock server: as a standalone server, under the control of your Gleam code, and inside integration tests.

## Standalone mode

The standalone server uses the fixed port 3004 and runs until you stop it:

```bash
make run
```

Then access the endpoints at `http://localhost:3004/`.

## Programmatic control

Start and stop the server from Gleam code, for example in tests. `server.start(port)` starts the server on a port. `server.stop(handle)` stops it. `stop` returns when the server is down and its port is closed, and a second call does nothing.

`http_helper` and `port` are small test helpers in this module's `test/snippets/` folder.

### Start, use and stop the server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/programmatic_control.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/server
import gleam/int
import gleam/result
import gleam/string
import snippets/http_helper

pub fn fetch_text(port: Int) -> Result(#(Int, String), String) {
  // Start server
  use handle <- result.try(start_server(port))

  // Use server
  let response =
    http_helper.get("http://localhost:" <> int.to_string(port) <> "/text")

  // Stop server
  server.stop(handle)
  response
}

fn start_server(port: Int) -> Result(server.ServerHandle, String) {
  server.start(port)
  |> result.map_error(string.inspect)
}
```

## Integration testing

Dream's HTTP client tests use the mock server in this way. This test starts the server on a free port from the operating system:

### A test against the mock server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/integration_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import gleam/int
import snippets/http_helper
import snippets/port

pub fn tests() -> TestSuite {
  describe("mock server", [
    it("streams ten chunks from /stream/fast", fn() {
      // Arrange
      let port = port.free_port()
      let assert Ok(mock) = server.start(port)

      // Act: send the request to http://localhost:<port>
      let response =
        http_helper.get(
          "http://localhost:" <> int.to_string(port) <> "/stream/fast",
        )
      server.stop(mock)

      // Assert
      response
      |> should
      |> be_equal(
        Ok(#(
          200,
          "Chunk 1\nChunk 2\nChunk 3\nChunk 4\nChunk 5\nChunk 6\nChunk 7\nChunk 8\nChunk 9\nChunk 10\n",
        )),
      )
      |> or_fail_with("Expected ten chunks from /stream/fast")
    }),
  ])
}
```

To give each path your own status and body, start the server with `server.start_with_config` instead. See the config mode guide.

## See also

- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): install the package and run a first test body against the server
- [Config mode](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/config-mode.md): give each path your own status and body
- [Non-streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/non-streaming-endpoints.md): the endpoint reference for the REST-like endpoints
- [Streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/streaming-endpoints.md): the endpoint reference for the chunked streams
- [How it works](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/how-it-works.md): streaming technique, timing, architecture and dependencies
- [README](https://github.com/TrustBound/dream_mock_server/blob/main/README.md)
