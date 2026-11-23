# Streaming endpoints

This guide is the reference for the streaming endpoints of the default server that `server.start` starts. Each endpoint sends its body in chunks, with deterministic delays between the chunks.

## `GET /stream/fast`

**10 chunks at 100ms intervals**

- Fast streaming for quick response handling
- Total duration: ~1 second
- Each chunk: `"Chunk N\n"`

**Use for:** Testing fast streaming, basic functionality

## `GET /stream/slow`

**5 chunks at 2s intervals**

- Slow streaming for timeout handling
- Total duration: ~10 seconds
- Each chunk: `"Chunk N\n"`

**Use for:** Testing timeout handling, long-running streams

## `GET /stream/burst`

**7 chunks with variable delays (100-500ms)**

- Deterministic burst pattern for robustness testing
- Delays: `[100, 500, 200, 400, 100, 300, 200]` ms
- Each chunk: `"Burst N\n"`

**Use for:** Testing variable timing patterns, buffering behavior

## `GET /stream/error`

**3 chunks then 500 status**

- Returns HTTP 500 with partial content
- Simulates mid-stream error
- Each chunk: `"Error test chunk N\n"`

**Use for:** Testing error handling mid-stream

## `GET /stream/huge`

**100 chunks with 10ms delays**

- Large response for memory/performance testing
- Total duration: ~1 second
- Each chunk: `"Huge chunk N\n"`

**Use for:** Memory efficiency, performance testing

## `GET /stream/json`

**5 JSON objects at 200ms intervals**

- Structured data streaming
- Each chunk: `{"event":"chunk","number":N,"message":"JSON event N"}\n`
- Content-Type: `application/json`

**Use for:** Testing structured data streaming, JSON handling

## `GET /stream/binary`

**256 binary chunks with byte patterns**

- Non-text streaming
- Each chunk: 4 bytes with repeating pattern
- Content-Type: `application/octet-stream`

**Use for:** Testing binary data streaming

## See also

- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): install the package and run a first test body against the server
- [Run the server](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md): standalone mode, start and stop from Gleam, and use in integration tests
- [Config mode](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/config-mode.md): give each path your own status and body
- [Non-streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/non-streaming-endpoints.md): the endpoint reference for the REST-like endpoints
- [How it works](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/how-it-works.md): streaming technique, timing, architecture and dependencies
- [README](https://github.com/TrustBound/dream_mock_server/blob/main/README.md)
