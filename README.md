<div align="center">
  <img src="https://raw.githubusercontent.com/TrustBound/dream/main/ricky_and_lucy.png" alt="Ricky Moony and Lucy, a moon shaped mascot for Dream with the star shaped mascot for Gleam, each with cute cartoon eyes and a smile" width="200">

<b>General-purpose HTTP mock server developed by Dream - provides both streaming and non-streaming endpoints for testing HTTP clients</b>

</div>

<br />

<div align="center">
  <a href="https://hex.pm/packages/dream_mock_server">
    <img src="https://img.shields.io/hexpm/v/dream_mock_server" alt="Hex Package">
  </a>
  <a href="https://github.com/TrustBound/dream_mock_server/releases">
    <img src="https://img.shields.io/github/v/release/TrustBound/dream_mock_server?label=Release" alt="Latest Release">
  </a>
  <a href="https://hexdocs.pm/dream_mock_server">
    <img src="https://img.shields.io/badge/hex-docs-lightgreen.svg" alt="HexDocs">
  </a>
  <a href="https://github.com/TrustBound/dream_mock_server/actions/workflows/ci.yml?query=branch%3Amain">
    <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/TrustBound/dream_mock_server/badges/coverage.json" alt="Coverage">
  </a>
  <a href="https://github.com/TrustBound/dream_mock_server/blob/main/LICENSE.md">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
  </a>
</div>

<br />

**Current module version:** `1.1.1`

## Overview

This module provides a comprehensive set of endpoints for testing HTTP clients:

- **Non-streaming endpoints** - Standard REST-like endpoints (GET, POST, PUT, DELETE)
- **Streaming endpoints** - Various streaming behaviors for testing chunked responses

All endpoints are deterministic and designed for testing, making them ideal for:

- **Testing** - Use as a test fixture for HTTP client integration tests
- **Demo** - Show HTTP behavior, such as streams and redirects, in a predictable way
- **Learning** - Study different HTTP patterns and error handling

## Running

### Standalone Mode

Start the server on port 3004:

```bash
make run
```

Then access endpoints at `http://localhost:3004/`

### Programmatic Mode

Use in tests or other applications:

#### Run a test body against the mock server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/programmatic_mode.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/server
import gleam/int
import gleam/otp/actor

pub fn with_mock_server(
  port: Int,
  test_body: fn(String) -> outcome,
) -> Result(outcome, actor.StartError) {
  case server.start(port) {
    Ok(handle) -> {
      // Make HTTP requests to the base URL, http://localhost:<port>
      let outcome = test_body("http://localhost:" <> int.to_string(port))
      server.stop(handle)
      Ok(outcome)
    }
    Error(start_error) -> Error(start_error)
  }
}
```

### Config mode

For proxy tests or any test that needs a **deterministic upstream** with specific status and body per path, start the server with a config list. The mock has no built-in provider logic (no OpenAI, Google, AWS, etc.); the caller supplies all path → (status, body) mappings. First matching route in the list wins.

#### Start with one prefix route <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_prefix.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/config.{type MockRoute, MockRoute, Prefix}
import dream_mock_server/server
import gleam/option.{None}
import gleam/otp/actor

/// One route: path /v1/chat/completions (prefix match), any method, 200 + JSON body
pub fn chat_completion_routes() -> List(MockRoute) {
  [
    MockRoute(
      path: "/v1/chat/completions",
      path_match: Prefix,
      method: None,
      status: 200,
      body: "{\"choices\":[{\"message\":{\"content\":\"\"}}]}",
    ),
  ]
}

pub fn start_chat_mock(
  port: Int,
) -> Result(server.ServerHandle, actor.StartError) {
  // Point your proxy or client at http://localhost:<port>,
  // then call server.stop(handle).
  server.start_with_config(port, chat_completion_routes())
}
```

#### How matching works

- Matching is **first route wins** in list order.
- `Exact` means request path must equal `path`.
- `Prefix` means request path must start with `path`.
- `method: Some(Get)` (or Post/Put/Delete/Patch from `gleam/http`) restricts by method.
- A request with the method CONNECT, TRACE or a method that is not standard is handled as GET.
- `method: None` matches any method.
- No match returns `404` with body `"Not found"`.
- A HEAD or OPTIONS request returns `404` with body `"Route not found"`.

#### Exact + method-specific example <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_method_specific.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/config.{type MockRoute, Exact, MockRoute}
import gleam/http.{Get, Post}
import gleam/option.{Some}

// GET /resource  -> 200 {"ok":true}
// POST /resource -> 201 {"created":true}
pub fn resource_routes() -> List(MockRoute) {
  [
    MockRoute("/resource", Exact, Some(Get), 200, "{\"ok\":true}"),
    MockRoute("/resource", Exact, Some(Post), 201, "{\"created\":true}"),
  ]
}
```

#### Ordering gotcha (important)

If you mix broad prefixes and specific routes, put specific routes first:

##### Good: specific route first <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_ordering.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/config.{type MockRoute, Exact, MockRoute, Prefix}
import gleam/option.{None}

// Good: specific before broad prefix
pub fn api_routes() -> List(MockRoute) {
  [
    MockRoute("/api/special", Exact, None, 200, "special"),
    MockRoute("/api", Prefix, None, 200, "general"),
  ]
}
```

- **Path match:** `Exact` (path must equal) or `Prefix` (path must start with).
- **Method:** `Some(Get)` etc. to restrict; `None` for any method.
- **Order:** Put more specific routes before broader prefix routes so they match first.
- **No match:** Returns 404 with body `"Not found"`.

## Non-Streaming Endpoints

### `GET /get`

**Returns JSON with request info**

- Returns: `{"method": "GET", "url": "/get", "query": "<raw query string>", "headers": []}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing GET requests, JSON parsing

### `POST /post`

**Echoes request body as JSON**

- Returns: `{"method": "POST", "url": "/post", "data": "<request body>"}`
- Status: 201 Created
- Content-Type: `application/json`

**Use for:** Testing POST requests, request body handling

### `PUT /put`

**Echoes request body as JSON**

- Returns: `{"method": "PUT", "url": "/put", "data": "<request body>"}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing PUT requests

### `DELETE /delete`

**Returns success response**

- Returns: `{"method": "DELETE", "url": "/delete"}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing DELETE requests

### `GET /json`

**Returns simple JSON object**

- Returns: `{"message": "Hello, World!", "success": true}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing JSON parsing, simple responses

### `GET /text`

**Returns plain text**

- Returns: `"Hello, World!"`
- Status: 200 OK
- Content-Type: `text/plain`

**Use for:** Testing text responses

### `GET /uuid`

**Returns UUID-like string**

- Returns: `{"uuid": "123e4567-e89b-12d3-a456-426614174000"}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing small JSON responses

### `GET /`

**Info page** - Lists all available endpoints with descriptions

**Use for:** Documentation, service discovery

## Streaming Endpoints

### `GET /stream/fast`

**10 chunks at 100ms intervals**

- Fast streaming for quick response handling
- Total duration: ~1 second
- Each chunk: `"Chunk N\n"`

**Use for:** Testing fast streaming, basic functionality

### `GET /stream/slow`

**5 chunks at 2s intervals**

- Slow streaming for timeout handling
- Total duration: ~10 seconds
- Each chunk: `"Chunk N\n"`

**Use for:** Testing timeout handling, long-running streams

### `GET /stream/burst`

**7 chunks with variable delays (100-500ms)**

- Deterministic burst pattern for robustness testing
- Delays: `[100, 500, 200, 400, 100, 300, 200]` ms
- Each chunk: `"Burst N\n"`

**Use for:** Testing variable timing patterns, buffering behavior

### `GET /stream/error`

**3 chunks then 500 status**

- Returns HTTP 500 with partial content
- Simulates mid-stream error
- Each chunk: `"Error test chunk N\n"`

**Use for:** Testing error handling mid-stream

### `GET /stream/huge`

**100 chunks with 10ms delays**

- Large response for memory/performance testing
- Total duration: ~1 second
- Each chunk: `"Huge chunk N\n"`

**Use for:** Memory efficiency, performance testing

### `GET /stream/json`

**5 JSON objects at 200ms intervals**

- Structured data streaming
- Each chunk: `{"event":"chunk","number":N,"message":"JSON event N"}\n`
- Content-Type: `application/json`

**Use for:** Testing structured data streaming, JSON handling

### `GET /stream/binary`

**256 binary chunks with byte patterns**

- Non-text streaming
- Each chunk: 4 bytes with repeating pattern
- Content-Type: `application/octet-stream`

**Use for:** Testing binary data streaming

## Integration Tests

The Gherkin scenarios in `test/features/mock_server.feature` run with
[dream_test](https://hexdocs.pm/dream_test)'s Gherkin support, as part of
`gleam test`. Each scenario starts the server on a free port, sends real HTTP
requests to it and stops it. The step definitions are in
`test/features/mock_server_feature.gleam`.

The scenarios verify:
- All endpoints return correct status codes
- Content format and structure
- Chunk counts and timing
- Error handling
- JSON validity

## Usage Modes

### 1. Standalone Server

Fixed port 3004, runs indefinitely:

```bash
make run
```

### 2. Programmatic Control

Start/stop programmatically for tests. `http_helper` and `port` are small test helpers in this module's `test/snippets/` folder.

#### Start, use and stop the server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/programmatic_control.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

### 3. Integration Testing

Dream's HTTP client tests use the mock server in this way. This test starts the server on a free port from the operating system:

#### A test against the mock server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/integration_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## Implementation Details

### Streaming Technique

A streaming endpoint returns a `Yielder(BitArray)`. The server sends one chunk
for each element, and asks for the next element only after it sent the last
one. So a `process.sleep` in the yielder sets the time between the chunks.

#### Fast stream chunks <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/streaming_technique.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/bit_array
import gleam/erlang/process
import gleam/int
import gleam/yielder.{type Yielder}

/// The chunks of `GET /stream/fast`. The server sends one chunk for each
/// element, and asks for the next element only after it sent the last one.
pub fn fast_chunks() -> Yielder(BitArray) {
  yielder.range(1, 10)
  |> yielder.map(create_fast_chunk)
}

fn create_fast_chunk(number: Int) -> BitArray {
  process.sleep(100)
  let line = "Chunk " <> int.to_string(number) <> "\n"
  bit_array.from_string(line)
}
```

### Non-Streaming Technique

A non-streaming endpoint builds its whole body, then the server sends it with a
`content-length` header. The JSON endpoints build their bodies with
`gleam_json`:

#### Echo JSON body <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/non_streaming_technique.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/json

/// The JSON body of an echo answer: the method and the path of the request
/// in one object, for example `{"method":"DELETE","url":"/delete"}`.
pub fn echo_body(method: String, path: String) -> String {
  json.object([
    #("method", json.string(method)),
    #("url", json.string(path)),
  ])
  |> json.to_string
}
```

### Timing Control

Streaming endpoints use `process.sleep()` between chunks for deterministic timing:

- **Fast**: 100ms delays
- **Slow**: 2000ms delays
- **Burst**: Variable 100-500ms delays
- **Huge**: 10ms delays (optimized for throughput)

### Error Simulation

The `/stream/error` endpoint demonstrates mid-stream errors by returning a 500 status with partial content. This tests client error handling during streaming.

## Architecture

The mock server has a pure core and a thin adapter. The core decides the
answer to each request and has no socket, so its tests call it directly. The
adapter connects the core to
[dream_http_server](https://hexdocs.pm/dream_http_server), the HTTP server.

```text
src/
├── standalone.gleam                    # Standalone entry point (port 3004)
├── compression_ffi.erl                 # zlib compression
├── dream_mock_server_ffi.erl           # Port check and server stop
└── dream_mock_server/
    ├── server.gleam                    # Programmatic start/stop functions
    ├── config.gleam                    # Config mode route types
    ├── compression.gleam               # Compression helpers
    ├── internal/
    │   ├── message.gleam               # Request and response types of the core
    │   ├── routes.gleam                # Route match: which endpoint answers
    │   ├── path.gleam                  # Path segments for the route match
    │   ├── api_endpoints.gleam         # Non-streaming endpoints
    │   ├── stream_endpoints.gleam      # Streaming endpoints and the info page
    │   ├── config_endpoint.gleam       # Config mode endpoint
    │   ├── mist_adapter.gleam          # Converts between the core and the server
    │   └── standalone_runner.gleam     # Runs the server for standalone.main
    └── views/
        ├── api_view.gleam              # JSON and text bodies
        └── index_view.gleam            # Info page text
```

The modules in `internal/` are not part of the public API.

## Dependencies

- **dream_http_server** - The HTTP server (a fork of mist)
- **gleam_http** - HTTP methods
- **gleam_erlang** - Process control (sleep)
- **gleam_otp** - The start error type
- **gleam_json** - JSON encoding
- **gleam_yielder** - Stream generation

The mock server does not depend on the Dream web framework.

## All Examples Are Tested

The core usage examples in this README are backed by runnable snippet tests
under `test/snippets/` and executed by `test/snippets_test.gleam`.

Run them with:

```bash
gleam test
```

## See Also

- [Dream Streaming Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/guides/streaming.md)
- [Dream HTTP Client](https://github.com/TrustBound/dream_http_client)
- [Streaming Capabilities Example](https://github.com/TrustBound/dream/tree/3.0.0/examples/streaming_capabilities)

## Contributing

See [CONTRIBUTING.md](https://github.com/TrustBound/dream_mock_server/blob/main/CONTRIBUTING.md).

Run `make check-snippets` to check that each code block in the docs matches a tested snippet file.

---

## License

MIT — see [LICENSE.md](https://github.com/TrustBound/dream_mock_server/blob/main/LICENSE.md)

---

<div align="center">
  <sub>Built in Gleam, on the BEAM, by the <a href="https://github.com/trustbound/dream">Dream Team</a> ❤️</sub>
</div>
