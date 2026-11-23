# How it works

This guide explains how the mock server makes its answers: the streaming and non-streaming techniques, the timing, the structure of the source, the dependencies, and the tests of this package.

## Streaming technique

A streaming endpoint returns a `Yielder(BitArray)`. The server sends one chunk
for each element, and asks for the next element only after it sent the last
one. So a `process.sleep` in the yielder sets the time between the chunks.

### Fast stream chunks <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/streaming_technique.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## Non-streaming technique

A non-streaming endpoint builds its whole body, then the server sends it with a
`content-length` header. The JSON endpoints build their bodies with
`gleam_json`:

### Echo JSON body <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/non_streaming_technique.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## Timing control

Streaming endpoints use `process.sleep()` between chunks for deterministic timing:

- **Fast**: 100ms delays
- **Slow**: 2000ms delays
- **Burst**: Variable 100-500ms delays
- **Huge**: 10ms delays (optimized for throughput)

## Error simulation

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

- **dream_http_server**: The HTTP server (a fork of mist)
- **gleam_http**: HTTP methods
- **gleam_erlang**: Process control (sleep)
- **gleam_otp**: The start error type
- **gleam_json**: JSON encoding
- **gleam_yielder**: Stream generation

The mock server does not depend on the Dream web framework.

## Tests of this package

### Integration tests

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

### All examples are tested

The examples in the README and in these guides are backed by runnable snippet
tests under `test/snippets/` and executed by `test/snippets_test.gleam`.

Run them with:

```bash
gleam test
```

## See also

- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): install the package and run a first test body against the server
- [Run the server](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md): standalone mode, start and stop from Gleam, and use in integration tests
- [Config mode](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/config-mode.md): give each path your own status and body
- [Non-streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/non-streaming-endpoints.md): the endpoint reference for the REST-like endpoints
- [Streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/streaming-endpoints.md): the endpoint reference for the chunked streams
- [README](https://github.com/TrustBound/dream_mock_server/blob/main/README.md)
