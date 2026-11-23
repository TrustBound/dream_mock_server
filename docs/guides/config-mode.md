# Config mode

This guide shows how to start the mock server with your own list of routes, so that each path gives the status and body that you choose.

## When to use config mode

Use config mode for proxy tests, or for any test that needs a **deterministic upstream** with a specific status and body for each path. Start the server with a config list. The mock has no built-in provider logic (no OpenAI, Google, AWS, and similar). The caller supplies all path → (status, body) mappings. The first matching route in the list wins.

## Start the server with a config list

### Start with one prefix route <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_prefix.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## How matching works

- Matching is **first route wins** in list order.
- `Exact` means the request path must equal `path`.
- `Prefix` means the request path must start with `path`.
- `method: Some(Get)` (or Post, Put, Delete, Patch from `gleam/http`) restricts by method.
- A request with the method CONNECT, TRACE or a method that is not standard is handled as GET.
- `method: None` matches any method.
- No match returns `404` with body `"Not found"`.
- A HEAD or OPTIONS request returns `404` with body `"Route not found"`.

## Exact and method-specific routes

### Exact + method-specific example <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_method_specific.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## Ordering gotcha (important)

If you mix broad prefixes and specific routes, put the specific routes first:

### Good: specific route first <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_ordering.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## Summary

- **Path match:** `Exact` (path must equal) or `Prefix` (path must start with).
- **Method:** `Some(Get)` and similar to restrict. `None` for any method.
- **Order:** Put more specific routes before broader prefix routes so they match first.
- **No match:** Returns 404 with body `"Not found"`.

## See also

- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): install the package and run a first test body against the server
- [Run the server](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md): standalone mode, start and stop from Gleam, and use in integration tests
- [Non-streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/non-streaming-endpoints.md): the endpoint reference for the REST-like endpoints
- [Streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/streaming-endpoints.md): the endpoint reference for the chunked streams
- [How it works](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/how-it-works.md): streaming technique, timing, architecture and dependencies
- [README](https://github.com/TrustBound/dream_mock_server/blob/main/README.md)
