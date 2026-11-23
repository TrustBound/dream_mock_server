<div align="center">
  <img src="https://raw.githubusercontent.com/TrustBound/dream/main/ricky_and_lucy.png" alt="Ricky Moony and Lucy, a moon shaped mascot for Dream with the star shaped mascot for Gleam, each with cute cartoon eyes and a smile" width="200">

<b>General-purpose HTTP mock server developed by Dream - provides both streaming and non-streaming endpoints for testing HTTP clients</b>

</div>

<br />

<div align="center">
  <a href="https://hex.pm/packages/dream_mock_server"><img src="https://img.shields.io/hexpm/v/dream_mock_server" alt="Hex Package"></a>
  <a href="https://github.com/TrustBound/dream_mock_server/releases"><img src="https://img.shields.io/github/v/release/TrustBound/dream_mock_server?label=Release" alt="Latest Release"></a>
  <a href="https://hexdocs.pm/dream_mock_server"><img src="https://img.shields.io/badge/hex-docs-lightgreen.svg" alt="HexDocs"></a>
  <a href="https://github.com/TrustBound/dream_mock_server/actions/workflows/ci.yml?query=branch%3Amain"><img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/TrustBound/dream_mock_server/badges/coverage.json" alt="Coverage"></a>
  <a href="https://github.com/TrustBound/dream_mock_server/blob/main/LICENSE.md"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
</div>

<br />

**Current module version:** `2.0.0`

# dream_mock_server

A general-purpose HTTP mock server for testing HTTP clients. It has non-streaming and streaming endpoints, and a config mode in which you choose the status and body for each path. All endpoints are deterministic and designed for testing. The mock server does not depend on the Dream web framework, so you can use it in any Gleam project.

## Features

- ✅ Non-streaming endpoints: standard REST-like endpoints (GET, POST, PUT, DELETE)
- ✅ Streaming endpoints: fast, slow, burst, error, huge, JSON and binary chunked responses
- ✅ Config mode: your own status and body for each path, first matching route wins
- ✅ Start and stop the server from Gleam code, or run it standalone on port 3004
- ✅ Deterministic answers and timing, for use as a test fixture
- ✅ No dependency on the Dream web framework

## Installation

```bash
gleam add dream_mock_server
```

## Quick Start

### Run a test body against the mock server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/programmatic_mode.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/docs/guides/getting-started.md#run-a-test-body-against-the-mock-server-"><img align="right" alt="Guide" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>

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

## Guides

- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): start the server in a test, run your code against it, and check what your code sends
- [Test how your client handles failures](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/testing-failures.md): error statuses, bodies that are not text, timeouts, a server that is down, content encodings and broken streams
- [Stand in for a third-party API](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md): config mode, with your own status and body for each path, for example a chat completion API
- [Run the server while you develop](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md): run the built-in server or your own stand-in until you stop it
- [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md): every built-in endpoint, with its status, headers, body and timing

## See Also

- [Dream Streaming Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/guides/streaming.md)
- [Dream HTTP Client](https://github.com/TrustBound/dream_http_client)
- [Streaming Capabilities Example](https://github.com/TrustBound/dream/tree/3.0.0/examples/streaming_capabilities)

## Contributing

See [CONTRIBUTING.md](https://github.com/TrustBound/dream_mock_server/blob/main/CONTRIBUTING.md).

Run `make check-snippets` to check that each code block in the docs is proven: a Gleam block is a copy of a tested snippet file, an output block is a copy of an output file that a test compares with the real output, and a command block is a copy of lines of a script that the tests or CI run.

---

## License

MIT — see [LICENSE.md](https://github.com/TrustBound/dream_mock_server/blob/main/LICENSE.md)

---

<div align="center">
  <sub>Built in Gleam, on the BEAM, by the <a href="https://github.com/trustbound/dream">Dream Team</a> ❤️</sub>
</div>
