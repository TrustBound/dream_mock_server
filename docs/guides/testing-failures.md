# Test how your client handles failures

The happy path is easy to test, because the real service gives it to you every time. The failures are the hard part: a 503 during a deploy, a server that takes too long, an error page that isn't even text, a body in an encoding you didn't expect, a stream that stops halfway. They happen in production and almost never on your machine, so the code that handles them is often the code nobody ran. The mock server has an endpoint for each of these, with the same answer every time. This guide builds a client function that tells the failures apart, and tests each case against the server.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Which endpoint tests which failure](#which-endpoint-tests-which-failure)
- [Step 1: Tell error statuses apart](#step-1-tell-error-statuses-apart)
- [Step 2: Keep an error body that isn't text](#step-2-keep-an-error-body-that-isnt-text)
- [Step 3: Give up on a slow server](#step-3-give-up-on-a-slow-server)
- [Step 4: Report a server that isn't there](#step-4-report-a-server-that-isnt-there)
- [Step 5: Handle content encodings](#step-5-handle-content-encodings)
- [Step 6: Streams that fail](#step-6-streams-that-fail)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Write a `fetch_text` function that returns a different error for each kind of failure.
- Check it against an error status, an error body that isn't UTF-8, a slow server, a closed port and two content encodings.
- Learn what each streaming failure endpoint sends, and what a client that reads the whole body sees.
- Build the exact compressed bytes of the compression endpoints, to test your own decompression.
- Put it all in a test module, one test for each failure.

## Before you start

This guide builds on [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md). You need the same dev dependencies: `dream_mock_server`, `dream_test` and `gleam_httpc`.

```sh
gleam add --dev dream_mock_server gleam_httpc
```

The examples use `gleam_httpc` 5.0. Its behavior shows up in a few results below, such as what a timeout covers. With another client, the server sends the same bytes, but your client can turn them into different results. Run your own code against the same endpoints to see what it does.

## Which endpoint tests which failure

Every endpoint below is built in, so `server.start(port)` serves all of them. The [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md) has the exact headers and bytes of each one.

| You want to test | Request | What the server does |
|:---|:---|:---|
| Any status code | `GET /status/:code`, for example `/status/503` | Answers that status with the body `{"status":503}` |
| An error body that isn't text | `GET /non-utf8-error` | Answers 400 with bytes that aren't valid UTF-8 |
| A slow answer | `GET /slow` | Waits 5 seconds, then answers 200 |
| A redirect | `GET /redirect/301` (also 302, 303, 307, 308), `/redirect/chain`, `/redirect/absolute` | Answers the redirect with a `Location` header that leads to `/text` |
| An encoding the client doesn't support | `GET /unknown-encoding`, `GET /stream/unknown-encoding` | Sends plain text with `Content-Encoding: br` |
| A compressed body | `GET /gzip`, `GET /deflate`, `GET /stream/gzip`, `GET /stream/deflate` | Sends real gzip or deflate bytes |
| A body that can't be decompressed | `GET /corrupted-gzip` | Sends text with `Content-Encoding: gzip` |
| The encodings that the client asks for | `GET /echo-accept-encoding` | Answers with the `Accept-Encoding` header of the request |
| An error status on a stream | `GET /stream/error` | Streams 3 lines with status 500 |
| A connection that breaks mid-stream | `GET /stream/drop` | Streams 2 lines, then closes the connection |
| A stream with long pauses | `GET /stream/slow` | Streams 5 lines, one every 2 seconds |

A server that isn't there needs no endpoint at all: send the request to a port where nothing listens.

## Step 1: Tell error statuses apart

Start with the client function. It gets the text at a URL, and turns each kind of failure into its own error, so the code that calls it can act on each one:

### Fetch text and tell failures apart <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_failures_fetch_text.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/bit_array
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/result

pub type FetchError {
  /// The URL is not valid.
  BadUrl(url: String)
  /// Nothing accepts connections at the address.
  Unreachable
  /// The whole response did not arrive within the timeout.
  TimedOut
  /// The server answered with a status outside 2xx.
  Refused(status: Int, body: BitArray)
  /// The body has a content encoding that this code cannot read.
  UnsupportedEncoding(encoding: String)
  /// The body of a 2xx response is not UTF-8 text.
  NotText(body: BitArray)
}

/// Gets the text at `url`, and waits at most `timeout_ms` for the whole
/// response.
pub fn fetch_text(url: String, timeout_ms: Int) -> Result(String, FetchError) {
  use http_request <- result.try(
    request.to(url) |> result.replace_error(BadUrl(url)),
  )
  use response <- result.try(
    httpc.configure()
    |> httpc.timeout(timeout_ms)
    |> httpc.dispatch_bits(request.set_body(http_request, <<>>))
    |> result.map_error(describe_error),
  )
  use body <- result.try(check_status(response))
  use body <- result.try(check_encoding(response, body))
  bit_array.to_string(body) |> result.replace_error(NotText(body))
}

fn describe_error(error: httpc.HttpError) -> FetchError {
  case error {
    httpc.FailedToConnect(..) -> Unreachable
    httpc.ResponseTimeout -> TimedOut
    // Only `httpc.dispatch` checks for UTF-8. `dispatch_bits` never does.
    httpc.InvalidUtf8Response -> NotText(<<>>)
  }
}

fn check_status(response: Response(BitArray)) -> Result(BitArray, FetchError) {
  case response.status >= 200 && response.status < 300 {
    True -> Ok(response.body)
    False -> Error(Refused(status: response.status, body: response.body))
  }
}

fn check_encoding(
  response: Response(BitArray),
  body: BitArray,
) -> Result(BitArray, FetchError) {
  case response.get_header(response, "content-encoding") {
    Error(Nil) | Ok("identity") -> Ok(body)
    Ok(encoding) -> Error(UnsupportedEncoding(encoding))
  }
}
```

Here's what each part does:

- `dispatch_bits` sends the request and gives the body as bytes. The function checks the bytes itself, in the last line, so a body that isn't text can't hide the status. [Step 2](#step-2-keep-an-error-body-that-isnt-text) shows why that matters.
- `check_status` turns any status outside 2xx into `Refused`, with the status and the whole body. Error bodies often say what went wrong, so keep them.
- `check_encoding` refuses a body with a content encoding the function can't read. [Step 5](#step-5-handle-content-encodings) covers it.
- `describe_error` turns the errors of `gleam_httpc` into `Unreachable` and `TimedOut`.

Now point it at the status endpoints. `GET /status/:code` answers with any status you put in the path:

### The results of the status endpoints <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_failures_status_endpoints.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
fetch_text(".../text", 2000)          -> Ok("Hello, World!")
fetch_text(".../status/503", 2000)    -> Error(Refused(status: 503, body: <<"{\"status\":503}">>))
fetch_text(".../status/404", 2000)    -> Error(Refused(status: 404, body: <<"{\"status\":404}">>))
fetch_text(".../redirect/301", 2000)  -> Error(Refused(status: 301, body: <<>>))
```

The last line is worth a second look. `gleam_httpc` doesn't follow redirects unless you turn that on with `httpc.follow_redirects(True)`, so a 301 reaches your code as a status outside 2xx. If your client should follow redirects, `/redirect/301` through `/redirect/308` each lead to `/text`, and `/redirect/chain` takes two steps to get there. A client that follows them gets `Hello, World!`.

## Step 2: Keep an error body that isn't text

Error pages come from proxies, load balancers and crashed servers, not only from the API you call. Some of them aren't UTF-8 text. `GET /non-utf8-error` answers status 400 with the text `Error: ` and then four bytes that aren't valid UTF-8:

### The result of a body that isn't text <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_failures_non_utf8_error.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
fetch_text(".../non-utf8-error", 2000)
  -> Error(Refused(status: 400, body: <<"Error: ", 192, 193, 254, 255>>))
```

You get the status and every byte of the body. That's why `fetch_text` reads the body as bytes. If it used `httpc.send`, which reads the body as text, the same request would return `Error(InvalidUtf8Response)`, and the status 400 would be gone. Your code would know that something failed, but not that the server refused the request.

## Step 3: Give up on a slow server

A server that never answers is worse than one that fails, because your code waits for it. The fix is a timeout, and the test needs a server that's slower than the timeout. `GET /slow` waits 5 seconds before it answers:

### The results of the slow endpoints <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_failures_slow_endpoints.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
fetch_text(".../slow", 1000)         -> Error(TimedOut)
fetch_text(".../stream/slow", 5000)  -> Error(TimedOut)
```

The first line is the plain case: the answer would come after 5 seconds, and the client stops waiting after 1.

The second line shows what your client's timeout covers. `/stream/slow` sends its first line after 2 seconds and the next one 2 seconds later, for 10 seconds in all, so the server is never quiet for more than 2 seconds. It still times out, because the timeout of `gleam_httpc` covers the whole response. A client that streams can reset its clock with each chunk instead, and then the same stream with the same timeout succeeds. Run your client against `/stream/slow` to learn which kind you have, before a long download teaches you in production.

Keep the timeouts in tests short. The test of `/slow` with a 1000 ms timeout takes about a second, and the test of `/stream/slow` about five.

## Step 4: Report a server that isn't there

When the service is down, or the address is wrong, there's no server to answer. You don't need an endpoint for that. Start and stop a server, so you know the port is free, and send the request there:

### The result with no server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_failures_no_server.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
fetch_text("http://localhost:19849/text", 2000)  -> Error(Unreachable)
```

`Unreachable` comes from the `FailedToConnect` error of `gleam_httpc`. Your code can retry it later, because the request never reached a server.

## Step 5: Handle content encodings

A server can compress the body and say so in the `Content-Encoding` header. Your client either decompresses it, or must refuse it. Treating gzip bytes as text gives you garbage, not an error. `fetch_text` refuses every encoding except `identity`, and the endpoints check that:

### The results of the encoding endpoints <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_failures_encodings.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
fetch_text(".../identity", 2000)          -> Ok("Hello, World!")
fetch_text(".../unknown-encoding", 2000)  -> Error(UnsupportedEncoding("br"))
fetch_text(".../gzip", 2000)              -> Error(UnsupportedEncoding("gzip"))
```

`/unknown-encoding` says `br` but sends plain text, so it tests only that your client looks at the header. `/gzip` sends real gzip, and the last line shows that `gleam_httpc` doesn't decompress it: it hands you the compressed bytes, and the header is your only clue.

If your client does decompress, test it against the exact bytes. The module `dream_mock_server/compression` has the functions that the endpoints use, so your test can build the same bytes. `GET /gzip` sends `Hello, World!` in one gzip body, and this function builds it:

### Compress a body with gzip <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/compression_gzip.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/compression

/// The text `Hello, World!` as one gzip body.
pub fn gzip_body() -> BitArray {
  compression.gzip_compress(<<"Hello, World!":utf8>>)
}
```

The raw body of `GET /gzip` is equal to `gzip_body()`. `compression.deflate_compress` builds the body of `GET /deflate` in the same way, in the zlib format that `Content-Encoding: deflate` uses.

The streaming endpoints compress the lines `Chunk 1` to `Chunk 5` as one stream, and send it in 6 chunks: one for each line, and a last one that ends the stream. Each chunk is flushed, so a client can decompress each one as it arrives. Joined in order, the chunks are equal to this:

### Build the bytes of a gzip stream <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_failures_gzip_stream.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/compression
import gleam/bit_array

/// The body of `GET /stream/gzip`: the lines `Chunk 1` to `Chunk 5` as one
/// gzip stream.
pub fn expected_gzip_stream() -> BitArray {
  compression.gzip_compress_chunks([
    <<"Chunk 1\n":utf8>>,
    <<"Chunk 2\n":utf8>>,
    <<"Chunk 3\n":utf8>>,
    <<"Chunk 4\n":utf8>>,
    <<"Chunk 5\n":utf8>>,
  ])
  |> bit_array.concat
}
```

`compression.deflate_compress_chunks` does the same for `GET /stream/deflate`.

For the failure case, `GET /corrupted-gzip` sends the text `this is not valid gzip data at all` with `Content-Encoding: gzip`. A client that decompresses must report it as an error, not crash.

To check which encodings your client asks for, send it to `GET /echo-accept-encoding`. It answers with the `Accept-Encoding` header of the request, or an empty body when there's none. `gleam_httpc` sends none.

## Step 6: Streams that fail

The streaming endpoints send their body in chunks, with pauses between them. Two of them fail on purpose:

- `GET /stream/error` sends status 500, and then the 3 lines `Error test chunk 1` to `Error test chunk 3`, one every 100 ms. The status comes first, as it always does in HTTP, so a client knows about the error before the first chunk.
- `GET /stream/drop` sends status 200 and the lines `Drop chunk 1` and `Drop chunk 2`, and then closes the connection before the body ends. A client that streams gets both lines, and then must report a broken connection, not a short success.

A client that reads the whole body sees `/stream/error` as a normal error status:

### The result of a stream with an error status <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_failures_stream_error.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
fetch_text(".../stream/error", 2000)
  -> Error(Refused(status: 500, body: <<"Error test chunk 1\nError test chunk 2\nError test chunk 3\n">>))
```

`/stream/drop` is the endpoint that finds bugs. With `gleam_httpc` 5.0, the request doesn't return an error at all: the library raises an exception when the server closes the connection, and the process that sent the request crashes. So don't point `fetch_text` at it. If your code uses `gleam_httpc` and a server can drop a connection, send the request from a process that's allowed to crash, and watch it with a monitor.

To test a client that streams, see the [Streaming a response](https://github.com/TrustBound/dream_http_client/blob/main/docs/guides/streaming.md) guide of `dream_http_client`. It reads these same endpoints chunk by chunk, and tells an error status, a dropped connection and a silent server apart.

## Test your code

Here's a test module for `fetch_text`, with one test for each failure. Each test starts a server on its own port, so the tests can run at the same time:

### Test each failure of fetch_text <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_failures_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import snippets/guide_failures_fetch_text.{
  Refused, TimedOut, Unreachable, UnsupportedEncoding, fetch_text,
}

pub fn tests() -> TestSuite {
  describe("fetch_text failures", [
    it("reports an error status with its body", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_811)

      // Act
      let fetched = fetch_text("http://localhost:19811/status/503", 2000)
      server.stop(mock)

      // Assert
      fetched
      |> should
      |> be_equal(Error(Refused(status: 503, body: <<"{\"status\":503}">>)))
      |> or_fail_with("Expected status 503 with its body")
    }),
    it("keeps an error body that is not text", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_812)

      // Act
      let fetched = fetch_text("http://localhost:19812/non-utf8-error", 2000)
      server.stop(mock)

      // Assert
      fetched
      |> should
      |> be_equal(
        Error(Refused(status: 400, body: <<"Error: ", 192, 193, 254, 255>>)),
      )
      |> or_fail_with("Expected status 400 with the bytes of the body")
    }),
    it("gives up on a slow server", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_813)

      // Act
      // The server waits 5 seconds before it answers /slow
      let fetched = fetch_text("http://localhost:19813/slow", 1000)
      server.stop(mock)

      // Assert
      fetched
      |> should
      |> be_equal(Error(TimedOut))
      |> or_fail_with("Expected a timeout after 1 second")
    }),
    it("reports a server that is not there", fn() {
      // Arrange
      // Start and stop a server, so that nothing listens on the port
      let assert Ok(mock) = server.start(19_814)
      server.stop(mock)

      // Act
      let fetched = fetch_text("http://localhost:19814/text", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(Unreachable))
      |> or_fail_with("Expected the connection to fail")
    }),
    it("refuses an encoding it cannot read", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_815)

      // Act
      let fetched = fetch_text("http://localhost:19815/unknown-encoding", 2000)
      server.stop(mock)

      // Assert
      fetched
      |> should
      |> be_equal(Error(UnsupportedEncoding("br")))
      |> or_fail_with("Expected the br encoding to be refused")
    }),
  ])
}
```

The fourth test needs no endpoint. It starts and stops a server to free the port, and then sends the request into the void.

Each test asserts the whole error value, with its status and its body. A test that checks only "it's an error" passes when your code returns the wrong error, and that's the bug these tests are for.

## Common pitfalls

**A test timeout shorter than the endpoint.** *Symptom:* the test runner stops a test of `/slow` or `/stream/slow` with its own timeout, before your client gives up. *Fix:* `/slow` takes 5 seconds and `/stream/slow` 10. Give your client a timeout well below that, as the examples do, or raise the timeout of your test runner.

**Crash reports in the test output.** *Symptom:* each test of `/stream/drop` prints a long `CRASH REPORT` that names `stream_drop` and `intentional crash to drop connection`. *Fix:* nothing is broken. The endpoint stops its own process to close the connection, and Erlang logs that. The test result is what counts.

**Reading the body as text too early.** *Symptom:* a request to `/non-utf8-error` gives an error without a status, such as `InvalidUtf8Response`. *Fix:* get the body as bytes, check the status, and only then convert the body to text, as `fetch_text` does.

**Ignoring `Content-Encoding`.** *Symptom:* a response that "works" in your tests is garbage in production, where a proxy compresses it. *Fix:* check the header, as in [Step 5](#step-5-handle-content-encodings), and test with `/gzip` and `/unknown-encoding`.

**`gleam_httpc` against `/stream/drop`.** *Symptom:* the test process crashes with `unexpected_httpc_error` and `socket_closed_remotely`. *Fix:* that's how `gleam_httpc` 5.0 reports a closed connection. Send the request from a separate process, or test dropped streams with a client that streams.

## Where to go next

- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): start, use and stop the server in a test.
- [Stand in for a third-party API](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md): make an API stand-in answer with its own error statuses and bodies.
- [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md): the exact status, headers, body and timing of every endpoint.
- [Streaming a response](https://github.com/TrustBound/dream_http_client/blob/main/docs/guides/streaming.md) in `dream_http_client`: test a streaming client against these endpoints.
- [API reference on HexDocs](https://hexdocs.pm/dream_mock_server/dream_mock_server/compression.html): the compression functions and the rest of the package.
