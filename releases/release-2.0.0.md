# dream_mock_server 2.0.0 Release Notes

**Release Date:** 2026-11-24

This release builds the mock server directly on `dream_http_server`. It no longer depends on the Dream web framework. A project on any Dream version, or on no Dream at all, can use it to test an HTTP client.

It is a major version because the handle of a running server and the method of a route have new types, and the functions that gave Dream routers to your code are removed. Read the Migration Guide before you upgrade. Every endpoint except the info page of `GET /` answers as before. The package also moved to its own repository.

## Key Highlights

- **No Dream dependency**: the mock server needs an HTTP server, not a web framework. It now uses `dream_http_server`
- **`ServerHandle` is the mock server's own type (breaking)**: `start`, `start_with_config` and `stop` work as before
- **`MockRoute.method` is the standard method type (breaking)**: import the methods from `gleam/http`
- **Routers and controllers are no longer public (breaking)**: start the server with `server.start` or `server.start_with_config`
- **Every endpoint answers as before, except `GET /`**: the same status, headers, body bytes, chunks and timing
- **Its own repository**: `dream_mock_server` now lives at [TrustBound/dream_mock_server](https://github.com/TrustBound/dream_mock_server), with its own version and its own releases

## What's New

### Built on `dream_http_server`

Before this release, the mock server was a Dream application, so a project that used it also got Dream. That made a circle between packages: Dream's tests use `dream_http_client`, the client's tests use the mock server, and the mock server needed Dream.

The mock server now runs directly on `dream_http_server` 2.0.0, the HTTP server below Dream. Inside, a core with no socket decides each answer, and a thin adapter reads the request and sends bytes or a chunked stream.

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

### Every Endpoint Except `GET /` Answers as Before

No other endpoint changed. To prove that, 55 requests were recorded on the old code, one or more for each endpoint. Each one gets the same raw HTTP answer on the new code, except `GET /`. Its info page is fixed, as [Bug Fixes](#bug-fixes) tells. A request with the method CONNECT, TRACE or a method that is not standard now gets 404 on the built-in endpoints, because the server no longer changes its method into GET. [Bug Fixes](#bug-fixes) also tells about this change. Three of the 55 requests send a body to a path with no endpoint: their 404 answer now has `connection: close` in place of `connection: keep-alive`, because the server below closes a connection whose request body it did not read.

### Integration Scenarios Run in `gleam test`

The integration scenarios run on dream_test's Gherkin support inside `gleam test`. Elixir is no longer needed to run them.

### Its Own Repository

`dream_mock_server` moved out of the Dream repository. It has its own version, its own changelog and its own release workflow. The package name on Hex is the same as before.

### Guides

The package has four guides in [`docs/guides/`](https://github.com/TrustBound/dream_mock_server/tree/main/docs/guides), each built around a task: getting started, testing how a client handles failures, standing in for a third-party API, and running the server while you develop. An endpoint reference lists every built-in endpoint with its status, headers, body and timing. Every code block in the guides, except the `git clone` command, is proven: each Gleam block is a tested snippet, each output block is a file that a test compares with the real output, and each command block is a part of a script that the tests or CI run. The README is short and links to them, and HexDocs shows them.

## Bug Fixes

- **The info page of `GET /` lists every built-in endpoint**: before, `index_view.format_index()` listed 15 of the 40 built-in endpoints. Now the page and the route match use one table of the built-in endpoints, so the page cannot leave out an endpoint that answers.
- **The info page names no fixed port**: before, it always said `Server: localhost:3004`, also on other ports. The line `Content-Type: All endpoints return appropriate MIME types` is also gone.
- **The info page tells the order of `/stream/error` correctly**: status 500 comes first, then 3 chunks. Before, the page said "3 chunks then 500 status".
- **A request keeps its method**: before, the server changed the methods CONNECT, TRACE and every method that is not standard, such as `PURGE`, into GET. So `TRACE /text` and `PURGE /text` got the answer of `GET /text`, and a `MockRoute` with one of those methods could never match. Now the route match uses the method that the request sent. On the built-in endpoints, `PURGE /text` and `TRACE /text` get status 404 with the body `Route not found`, the same answer as `DELETE /text`. In config mode, a route with `Some(http.Other("PURGE"))`, `Some(http.Trace)` or `Some(http.Connect)` matches a request with that method, and a route with `None` matches every method as before. A method name is case-sensitive, so `Purge` does not match `Other("PURGE")`. GET, POST, PUT, PATCH, DELETE, HEAD and OPTIONS get the same answers as before on the built-in endpoints.
- **HEAD and OPTIONS reach the routes in config mode**: before, a HEAD or OPTIONS request got 404 `Route not found` before any route was checked, so a `MockRoute` with `Some(http.Head)` or `Some(http.Options)` could never match. Now these requests go to the routes as every other method does. A route with `Some(http.Options)` answers OPTIONS, for example a CORS preflight with status 204. A route with `Some(http.Head)` or `None` answers HEAD with the headers of the route and no body. A request that matches no route gets 404 `Not found`, as for every other method.
- **A request body that the server does not read is never answered as a request**: `dream_http_server` 2.0.0 closes the connection after an answer when the request body was not read to its end, so the bytes of that body cannot reach the server as a second request.

## Known Limits

- The `standalone` module stops with a panic when port 3004 is in use, as before

## Testing

- 339 tests run, 0 failed, in about 65 seconds with the coverage check (Apple M1 Max, OTP 29, Gleam 1.19.2). Line coverage of `src/` is 100% (323 of 323 lines)
- `scripts/run-server-smoke.sh` starts and stops each command of the guide "Run the server while you develop" that serves until you stop it, in about 2 seconds
- Each of 55 recorded requests gets the same raw HTTP answer as before the move to `dream_http_server`, except `GET /`, whose info page is fixed, and three requests with a body to a path with no endpoint, whose 404 answer now has `connection: close`

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
- [dream_http_server](https://hexdocs.pm/dream_http_server) - v2.0.0
- [README](https://github.com/TrustBound/dream_mock_server/blob/main/README.md)
- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md)
- [Test how your client handles failures](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/testing-failures.md)
- [Stand in for a third-party API](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md)
- [Run the server while you develop](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md)
- [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md)
- [Changelog](https://github.com/TrustBound/dream_mock_server/blob/main/CHANGELOG.md)

## Community

- [Discussions](https://github.com/TrustBound/dream/discussions)
- [Report Issues](https://github.com/TrustBound/dream_mock_server/issues)
- [Contributing Guide](https://github.com/TrustBound/dream_mock_server/blob/main/CONTRIBUTING.md)
