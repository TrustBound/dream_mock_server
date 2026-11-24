# Changelog

All notable changes to `dream_mock_server` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - Unreleased

### Changed

- Moved to its own repository
- Built directly on `dream_http_server` 2.0.0. It no longer depends on the Dream web framework, so a project on any Dream version, or on no Dream at all, can use it.
- `server.ServerHandle` is now the mock server's own opaque type. `start`, `start_with_config` and `stop` work as before: `stop` returns when the server is down and its port is closed, and a second call does nothing.
- `MockRoute.method` is now an `Option` of `gleam/http.Method`. Import the methods from `gleam/http`, for example `import gleam/http.{Get, Post}`.
- Every endpoint except `GET /` answers as before, with the same status, headers, body bytes, chunks and timing.
- The integration scenarios run on dream_test's Gherkin support inside `gleam test`. Elixir is no longer needed.
- The package now has four guides in `docs/guides/`, each built around a task: getting started, testing how a client handles failures, standing in for a third-party API, and running the server while you develop. An endpoint reference lists every built-in endpoint. Every code block in the guides, except the `git clone` command, is proven: each Gleam block is a tested snippet, each output block is a file that a test compares with the real output, and each command block is a part of a script that the tests or CI run. The README is short and links to them, and HexDocs shows them.
- Every public function has a tested example in its doc comment, 19 functions in all.

### Fixed

- The info page of `GET /` (`index_view.format_index()`) now lists all 40 built-in endpoints. Before, it listed 15 of them. The page and the route match now use one table of the built-in endpoints, so the page cannot leave out an endpoint that answers. The page no longer says `Server: localhost:3004`, which was wrong on every other port, and it no longer has the line `Content-Type: All endpoints return appropriate MIME types`. It now says that `/stream/error` sends status 500 first and then its 3 chunks. Before, it said "3 chunks then 500 status".
- A request keeps its method. Before, the server changed CONNECT, TRACE and every method that is not standard, such as `PURGE`, into GET, so `TRACE /text` got the answer of `GET /text` and a `MockRoute` with one of those methods could never match. Now `PURGE /text` and `TRACE /text` get status 404 with the body `Route not found`, the same answer as `DELETE /text`. In config mode, a route with `Some(http.Other("PURGE"))`, `Some(http.Trace)` or `Some(http.Connect)` matches a request with that method. A method name is case-sensitive. The answers to GET, POST, PUT, PATCH, DELETE, HEAD and OPTIONS on the built-in endpoints do not change.
- HEAD and OPTIONS reach the routes in config mode. Before, they got 404 `Route not found` before any route was checked, so a `MockRoute` with `Some(http.Head)` or `Some(http.Options)` could never match. Now a route with `Some(http.Options)` answers OPTIONS, for example a CORS preflight with status 204, and a route with `Some(http.Head)` or `None` answers HEAD with the headers of the route and no body. A request that matches no route gets 404 `Not found`.
- A request body that the server does not read is never answered as a request: `dream_http_server` 2.0.0 closes the connection after the answer when the handler did not read the body to its end.

### Removed

- `router.create_router` and `router.create_config_router`. Use `server.start` and `server.start_with_config`.
- `config.MockConfigContext`.
- The public controller modules `controllers/api_controller`, `controllers/config_controller` and `controllers/stream_controller`. The endpoints are now internal modules.

### Testing

- 339 tests run, 0 failed, in about 65 seconds with the coverage check (Apple M1 Max, OTP 29, Gleam 1.19.2). Line coverage of `src/` is 100% (323 of 323 lines).
- `scripts/run-server-smoke.sh` starts and stops each command of the guide "Run the server while you develop" that serves until you stop it, in about 2 seconds.
- Each of 55 recorded requests, one or more for each endpoint, gets the same raw HTTP answer as before the move to `dream_http_server`, except four. The body of `GET /` is now the fixed info page, and its `content-length` changes with it. Three requests with a body to a path with no endpoint get the same 404, but with `connection: close` in place of `connection: keep-alive`.

## [1.1.1] - 2026-03-03

### Fixed

- **`GET /get` now actually echoes query parameters.** The endpoint was
  documented as echoing query parameters since 1.0.0, but the implementation
  only passed `request.path` to the view layer. Now passes `request.query` as
  well, and the JSON response includes a `"query"` field with the raw query
  string.

## [1.1.0] - 2026-02-15

### Added

- **Config mode:** `start_with_config(port, config)` starts the mock with a caller-provided list of routes (path, optional method, status, body). No built-in provider logic; first matching route wins; no match returns 404. Use for proxy tests or any deterministic upstream. New types: `dream_mock_server/config.{MockRoute, PathMatch, Exact, Prefix}`.

## [1.0.0] - 2025-11-24

### Added

**Initial Release**

- General-purpose HTTP mock server for testing HTTP clients
- Programmatic control with `start(port)` and `stop(handle)` functions
- Comprehensive HexDocs documentation
- Full Cucumber integration test suite

**Non-Streaming Endpoints**

- `GET /` - Info page with endpoint documentation
- `GET /get` - Echo query parameters
- `POST /post` - Echo request body
- `GET /status/:code` - Return specified HTTP status code (200-599)
- `GET /json` - Sample JSON response
- `GET /text` - Plain text response
- `GET /uuid` - Generate and return UUID
- `GET /large` - Large response (1MB) for memory/performance testing
- `GET /empty` - Empty response body
- `GET /slow` - Delayed response (2 seconds) for timeout testing

**Streaming Endpoints**

- `GET /stream/fast` - 10 chunks at 100ms intervals
- `GET /stream/slow` - 5 chunks at 2s intervals
- `GET /stream/burst` - Random burst pattern (5-10 chunks, 100-500ms delays)
- `GET /stream/huge` - 100 chunks for memory/performance testing

### Design Decisions

**Port Management**

- Explicit port required via `start(port)` - no random port assignment
- Follows Dream's "explicit over implicit" philosophy
- Ensures predictable test behavior

**Standalone Mode**

- Standalone server entry point at `src/standalone.gleam` (not `main.gleam`)
- Avoids module name conflicts with example applications
- Hardcoded to port 3004 for manual testing

**Error Simulation**

- No transport-layer error simulation (connection drops, timeouts)
- Transport failures belong in a different testing layer
- Mock server focuses on HTTP protocol testing

### Notes

This module was created to eliminate external test dependencies (httpbin.org) and provide a reliable, fast, local testing environment for HTTP clients.
