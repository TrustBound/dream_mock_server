<div align="center">
  <img src="https://raw.githubusercontent.com/TrustBound/dream/main/ricky_and_lucy.png" alt="Ricky Moony and Lucy, a moon shaped mascot for Dream with the star shaped mascot for Gleam, each with cute cartoon eyes and a smile" width="200">

<b>A mock HTTP server for testing your client. Real failures, on demand.</b>

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

## What is Dream Mock Server?

Dream Mock Server is an HTTP server you start inside a test, so your client talks to a real socket instead of a fake. It already serves the failures that clients get wrong: any status code, a gzip body that will not decompress, a stream that drops mid-way, a slow answer and every kind of redirect. Every answer and every pause is fixed, so a test gives the same result on every run.

## Features

### Built-in endpoints

Echo, status, redirect and encoding endpoints, ready when the server starts. [Read more](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md).

| Feature                | What you get                                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 🪞 **Echo endpoints**  | `GET /get`, `POST /post`, `PUT /put`, `PATCH /patch` and `DELETE /delete` answer with the request, so a test can check what the client sent |
| 🎚️ **Any status code** | `GET /status/:code` answers the status you ask for                                                                                          |
| ↪️ **Redirects**        | 301, 302, 303, 307 and 308, a chain, and an absolute `Location`                                                                             |
| 🗜️ **Compression**     | Real gzip and deflate bodies, an encoding the client does not support, and a corrupted gzip body                                            |

### Streaming

Chunked responses with fixed timing. [Read more](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md#streams).

| Feature               | What you get                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------ |
| 🌊 **Stream shapes**  | Fast, slow, burst, huge, JSON, binary, gzip and deflate streams                            |
| 💥 **Broken streams** | `/stream/error` answers 500, and `/stream/drop` closes the connection before the body ends |
| ⏱️ **Known timing**    | Each stream pauses a fixed time before each chunk                                          |

### Test failures

Which endpoint tests which failure of your client. [Read more](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/testing-failures.md).

| Feature                         | What you get                                                          |
| ------------------------------- | --------------------------------------------------------------------- |
| 🐢 **Slow answers**             | `GET /slow` waits 5 seconds, then answers 200                         |
| 🔤 **Bodies that are not text** | `GET /non-utf8-error` answers 400 with bytes that are not valid UTF-8 |

### Your own API

Config mode gives each path your own status and body. [Read more](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md).

| Feature                         | What you get                                                                                                                                                         |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🧩 **Your own routes**          | `server.start_with_config` with your own status and body for each path; the first matching route wins                                                                |
| 🏃 **Run it while you develop** | Run the built-in server or your own stand-in until you stop it. [Read more](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md) |

## A Quick Example

### Run a test body against the mock server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/programmatic_mode.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a> <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/docs/guides/getting-started.md#run-a-test-body-against-the-mock-server-"><img align="right" alt="Guide: Getting started" title="Guide: Getting started" src="https://img.shields.io/badge/%F0%9F%93%96_read-guide-blue.svg?style=flat-square"></a>

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

**Run this:** `with_mock_server(3004, test_body)` → the server runs while your test body makes requests to `base_url`, then stops, and you get `Ok(outcome)`.

## Installation

```sh
gleam add --dev dream_mock_server
```

## Guides

- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): start the server in a test, run your code against it, and check what your code sends
- [Test how your client handles failures](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/testing-failures.md): error statuses, bodies that are not text, timeouts, a server that is down, content encodings and broken streams
- [Stand in for a third-party API](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md): config mode, with your own status and body for each path, for example a chat completion API
- [Run the server while you develop](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md): run the built-in server or your own stand-in until you stop it
- [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md): every built-in endpoint, with its status, headers, body and timing
- [API reference](https://hexdocs.pm/dream_mock_server): every module and function on HexDocs

## Requirements

- Gleam 1.19.2 or newer (the version CI uses).
- Erlang/OTP 28 in CI. The server runs on the BEAM.
- Dependencies include `dream_http_server`, `gleam_otp` and `gleam_erlang`. The package needs no Dream web framework.

## About Dream

[Dream](https://github.com/TrustBound/dream) is a collection of Gleam packages for building production web applications. Each package implements its standards completely, shares the same naming and style as the others, and is fully tested. TrustBound builds Dream for its own production systems and shares it in the hope that it helps yours.

Dream Mock Server works on its own. You don't need the rest of Dream to use it.

## Contributing

See [CONTRIBUTING.md](https://github.com/TrustBound/dream_mock_server/blob/main/CONTRIBUTING.md).

Run `make check-snippets` to check that each code block in the docs is proven: a Gleam block is a copy of a tested snippet file, an output block is a copy of an output file that a test compares with the real output, and a command block is a copy of lines of a script that the tests or CI run.

## Contributing

See [CONTRIBUTING.md](https://github.com/TrustBound/dream_mock_server/blob/main/CONTRIBUTING.md).

Run `make check-snippets` to check that each code block in the docs is proven: a Gleam block is a copy of a tested snippet file, an output block is a copy of an output file that a test compares with the real output, and a command block is a copy of lines of a script that the tests or CI run.

## License

MIT — see [LICENSE.md](https://github.com/TrustBound/dream_mock_server/blob/main/LICENSE.md)
