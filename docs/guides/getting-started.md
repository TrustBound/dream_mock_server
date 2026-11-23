# Getting started

This guide shows how to add dream_mock_server to a Gleam project and run a first test body against the mock server.

## Install

Add the package as a dependency:

```bash
gleam add dream_mock_server
```

The mock server does not depend on the Dream web framework. A project on any Dream version, or on no Dream at all, can use it.

## What the server gives you

The mock server has a set of endpoints for testing HTTP clients:

- **Non-streaming endpoints**: standard REST-like endpoints (GET, POST, PUT, DELETE)
- **Streaming endpoints**: different streaming behaviors for testing chunked responses

All endpoints are deterministic and designed for testing. Use the server for:

- **Testing**: as a test fixture for HTTP client integration tests
- **Demo**: to show HTTP behavior, such as streams and redirects, in a predictable way
- **Learning**: to study different HTTP patterns and error handling

## Run a first test body

Start the server on a port with `server.start`, send your requests to `http://localhost:<port>`, then stop the server with `server.stop`. `stop` returns when the server is down and its port is closed. A second call does nothing.

### Run a test body against the mock server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/programmatic_mode.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

## Run the server on its own

From a clone of the repository, start the server on port 3004:

```bash
make run
```

Then access the endpoints at `http://localhost:3004/`. The `GET /` info page lists all available endpoints.

## See also

- [Run the server](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md): standalone mode, start and stop from Gleam, and use in integration tests
- [Config mode](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/config-mode.md): give each path your own status and body
- [Non-streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/non-streaming-endpoints.md): the endpoint reference for the REST-like endpoints
- [Streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/streaming-endpoints.md): the endpoint reference for the chunked streams
- [How it works](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/how-it-works.md): streaming technique, timing, architecture and dependencies
- [README](https://github.com/TrustBound/dream_mock_server/blob/main/README.md)
