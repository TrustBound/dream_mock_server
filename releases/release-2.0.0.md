# dream_mock_server 2.0.0 Release Notes

**Release Date:** not released yet (draft)

This release builds the mock server directly on `dream_http_server`. It no longer depends on the Dream web framework. A project on any Dream version, or on no Dream at all, can use it to test an HTTP client.

It is a major version because the handle of a running server and the method of a route have new types, and the functions that gave Dream routers to your code are removed. Read the Migration Guide before you upgrade. Every endpoint answers as before. The package also moved to its own repository.

## Key Highlights

- **No Dream dependency**: the mock server needs an HTTP server, not a web framework. It now uses `dream_http_server`
- **`ServerHandle` is the mock server's own type (breaking)**: `start`, `start_with_config` and `stop` work as before
- **`MockRoute.method` is the standard method type (breaking)**: import the methods from `gleam/http`
- **Routers and controllers are no longer public (breaking)**: start the server with `server.start` or `server.start_with_config`
- **Every endpoint answers as before**: the same status, headers, body bytes, chunks and timing
- **Its own repository**: `dream_mock_server` now lives at [TrustBound/dream_mock_server](https://github.com/TrustBound/dream_mock_server), with its own version and its own releases

## What's New

### Built on `dream_http_server`

Before this release, the mock server was a Dream application, so a project that used it also got Dream. That made a circle between packages: Dream's tests use `dream_http_client`, the client's tests use the mock server, and the mock server needed Dream.

The mock server now runs directly on `dream_http_server`, the HTTP server below Dream. Inside, a core with no socket decides each answer, and a thin adapter reads the request and sends bytes or a chunked stream.

### Start, Use and Stop the Server

`server.start(port)` and `server.start_with_config(port, routes)` return a `ServerHandle`. `server.stop(handle)` returns when the server is down and its port is closed. A second call does nothing.

#### Start, use and stop the server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/programmatic_control.gleam#L3-L25"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

### Every Endpoint Answers as Before

No endpoint changed. To prove that, 55 requests were recorded on the old code, one or more for each endpoint. Each one gets the same raw HTTP answer on the new code.

### Integration Scenarios Run in `gleam test`

The integration scenarios run on dream_test's Gherkin support inside `gleam test`. Elixir is no longer needed to run them.

### Its Own Repository

`dream_mock_server` moved out of the Dream repository. It has its own version, its own changelog and its own release workflow. The package name on Hex is the same as before.

### Guides

The package has guides in [`docs/guides/`](https://github.com/TrustBound/dream_mock_server/tree/main/docs/guides). The README is short and links to them, and HexDocs shows the guides.

## Known Limits

- CONNECT, TRACE and methods that are not standard are handled as GET, as before. A `MockRoute` with one of those methods can never match
- The `standalone` module stops with a panic when port 3004 is in use, as before

## Testing

- 233 tests run, 0 failed, in about 58 seconds with the coverage check (Apple M1 Max, OTP 29, Gleam 1.19.2). Line coverage of `src/` is 100% (306 of 306 lines)
- Each of 55 recorded requests gets the same raw HTTP answer as before the move to `dream_http_server`

## Upgrading

Update your dependencies:

```toml
[dev-dependencies]
dream_mock_server = ">= 2.0.0 and < 3.0.0"
```

Then run:

```bash
gleam deps update dream_mock_server
```

### Migration Guide

Most projects need only step 1 or no step at all. Steps 2 and 3 apply only in the cases they name.

#### 1. Your code names the type of the server handle

`server.ServerHandle` is now the mock server's own opaque type. Before, `start` returned the `ServerHandle` of Dream's server module. Where a type annotation names Dream's type, name `dream_mock_server/server.ServerHandle`. Code that only passes the handle to `server.stop` needs no change.

#### 2. Your config-mode routes name a method

`MockRoute.method` is now an `Option` of `gleam/http.Method`. Import the methods from `gleam/http`.

##### Routes for one path with two methods <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_method_specific.gleam#L3-L14"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

#### 3. Your code mounts the mock routes in its own Dream server

These are removed:

- `router.create_router` and `router.create_config_router`. Use `server.start` and `server.start_with_config`, and let the mock server listen on its own port
- `config.MockConfigContext`
- The public controller modules `controllers/api_controller`, `controllers/config_controller` and `controllers/stream_controller`. The endpoints are now internal modules

## Documentation

- [dream_mock_server](https://hexdocs.pm/dream_mock_server) - v2.0.0
- [dream_http_server](https://hexdocs.pm/dream_http_server) - v1.3.1
- [README](https://github.com/TrustBound/dream_mock_server/blob/main/README.md)
- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md)
- [Run the server](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md)
- [Config mode](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/config-mode.md)
- [Non-streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/non-streaming-endpoints.md)
- [Streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/streaming-endpoints.md)
- [How it works](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/how-it-works.md)
- [Changelog](https://github.com/TrustBound/dream_mock_server/blob/main/CHANGELOG.md)

## Community

- [Discussions](https://github.com/TrustBound/dream/discussions)
- [Report Issues](https://github.com/TrustBound/dream_mock_server/issues)
- [Contributing Guide](https://github.com/TrustBound/dream_mock_server/blob/main/CONTRIBUTING.md)
