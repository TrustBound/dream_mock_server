# Getting started

Your code talks to an HTTP service, and you want to test it. The real service is slow, costs money, needs keys, and never fails when you want it to. A fake function that returns a canned value skips the part that breaks most often: the HTTP request itself. `dream_mock_server` gives you a third choice. It's a real HTTP server that runs inside your tests on a local port, with endpoints whose answers never change. This guide takes you from an empty test to a test that sends real requests to it.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Which server to start](#which-server-to-start)
- [Step 1: Give your code a base URL](#step-1-give-your-code-a-base-url)
- [Step 2: Run your code against the mock server](#step-2-run-your-code-against-the-mock-server)
- [Step 3: Check what your code sends](#step-3-check-what-your-code-sends)
- [When the server can't start](#when-the-server-cant-start)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Write a client function that takes the address of the service as a parameter.
- Start the mock server on a port, run that function against it, and stop the server.
- Check the exact JSON body and content type that your code sends.
- Handle a port that's already in use.
- Put all of it in a test module that runs with `gleam test`.

## Before you start

Add the mock server as a dev dependency, so it's in your tests but not in your release:

```sh
gleam add --dev dream_mock_server
```

The examples send their requests with [gleam_httpc](https://hexdocs.pm/gleam_httpc). The mock server works with any HTTP client, so use the one your code already uses. To run the examples as they are, add it too:

```sh
gleam add --dev gleam_httpc
```

The test modules use [dream_test](https://github.com/TrustBound/dream_test). Add it as a dev dependency, with the version range that this package tests with:

### The dev dependency on dream_test <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/gleam.toml#L31-L32"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```toml
[dev-dependencies]
dream_test = ">= 3.0.0 and < 4.0.0"
```

The mock server doesn't depend on the Dream web framework. A project on any version of Dream, or on no Dream at all, can use it.

## Which server to start

The package can run the server in three ways. Pick the one that fits what you want to test:

| Your situation | Use | Why |
|:---|:---|:---|
| You test an HTTP client: how it sends requests, reads bodies, follows redirects, or handles errors | `server.start(port)` | It serves about forty built-in endpoints with fixed answers: echoes, status codes, slow answers, compressed bodies and streams. |
| You test code that calls one specific API, such as a payment or chat completion API | `server.start_with_config(port, routes)` | You choose the status and body for each path. The [Stand in for a third-party API](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md) guide shows how. |
| You want a server to send requests to by hand, with `curl` or a browser | `make run`, or your own `main` | The server runs until you stop it. The [Run the server while you develop](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md) guide shows how. |

This guide uses the first one.

## Step 1: Give your code a base URL

A test can only point your code at the mock server if your code lets it. So the first step is in your code, not in your tests: take the base URL of the service as a parameter, instead of writing the address into the function.

Here's a small client function that gets a greeting from `<base_url>/text`:

### Fetch a greeting from a base URL <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_getting_started_greeting.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/http/request
import gleam/httpc
import gleam/result
import gleam/string

pub type GreetingError {
  /// The URL is not valid.
  BadUrl(url: String)
  /// The request did not get a response.
  RequestFailed(reason: String)
  /// The server answered with a status other than 200.
  UnexpectedStatus(status: Int)
}

/// Fetches the greeting at `<base_url>/text`. Your program passes the URL
/// of the real service, and your tests pass the URL of the mock server.
pub fn fetch_greeting(base_url: String) -> Result(String, GreetingError) {
  let url = base_url <> "/text"
  use http_request <- result.try(
    request.to(url) |> result.replace_error(BadUrl(url)),
  )
  use response <- result.try(
    httpc.send(http_request)
    |> result.map_error(fn(error) { RequestFailed(string.inspect(error)) }),
  )
  case response.status {
    200 -> Ok(response.body)
    status -> Error(UnexpectedStatus(status))
  }
}
```

Your program calls `fetch_greeting` with the address of the real service, for example from its configuration. Your tests call it with the address of the mock server. The function itself doesn't know the difference, and that's the point: the code you test is the code you ship.

`GreetingError` keeps the three ways the call can fail apart. You'll see `RequestFailed` and `UnexpectedStatus` again below.

## Step 2: Run your code against the mock server

Now start a server, run the code, and stop the server. This function does exactly that, for any test body that takes a base URL:

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

Here's what each part does:

- `server.start(port)` starts the server with the built-in endpoints on `localhost` at that port. It returns when the server accepts connections, so you can send a request right away.
- The test body gets the base URL, `http://localhost:<port>`, and returns whatever it returns.
- `server.stop(handle)` returns when the server is down and its port is closed. A second call with the same handle does nothing.

Pass `fetch_greeting` from Step 1 as the test body:

### The greeting from the mock server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_getting_started_with_mock_server.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
with_mock_server(19831, fetch_greeting)
  -> Ok(Ok("Hello, World!"))
```

The outer `Ok` says the server started. The inner `Ok` is what `fetch_greeting` returned: `GET /text` always answers status 200 with the body `Hello, World!`.

Every built-in endpoint answers the same way each time, so you can compare results exactly. `GET /json`, `GET /uuid` and `GET /empty` give other fixed bodies, and the [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md) lists them all.

## Step 3: Check what your code sends

A greeting tests the response side. Most bugs in client code are on the request side: the wrong method, a body that isn't the JSON you meant, a missing header. The echo endpoints answer with what they got, so a test can look at it:

- `POST /post` answers status 201 with the method, the path and the request body as JSON. `PUT /put` and `PATCH /patch` do the same with status 200.
- `GET /get` answers with the path and the raw query string.
- `POST /content-type` answers with the `Content-Type` header of the request, as text.

This function sends a JSON body with a POST request:

### Send a JSON body <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_getting_started_post_json.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json.{type Json}
import gleam/result
import gleam/string

/// Sends `body` as JSON to `url` with a POST request. Returns the status and
/// the body of the response.
pub fn post_json(url: String, body: Json) -> Result(#(Int, String), String) {
  use http_request <- result.try(
    request.to(url) |> result.replace_error("Not a valid URL: " <> url),
  )
  let http_request =
    http_request
    |> request.set_method(http.Post)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json.to_string(body))
  use response <- result.try(
    httpc.send(http_request) |> result.map_error(string.inspect),
  )
  Ok(#(response.status, response.body))
}

/// The JSON of a new note.
pub fn note_json(text: String) -> Json {
  json.object([#("text", json.string(text))])
}
```

When it sends `note_json("Buy milk")` to `/post`, it returns `Ok(#(201, body))`, and `body` is this JSON text:

### The echo of the note <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_getting_started_note_echo.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
{"method":"POST","url":"/post","data":"{\"text\":\"Buy milk\"}"}
```

The `data` field holds your request body as a JSON string, so the quotes in it are escaped. Writing that by hand in a test is easy to get wrong. The module `dream_mock_server/views/api_view` has the functions that format these bodies, so your test can build the expected value instead:

- `api_view.post_to_json(path, body)`, `put_to_json`, and `patch_to_json` build the echo of `POST /post`, `PUT /put` and `PATCH /patch`.
- `api_view.get_to_json(path, query)` builds the echo of `GET /get`, and `delete_to_json(path)` the echo of `DELETE /delete`.
- `api_view.status_to_json(code)`, `simple_json_to_string()`, `uuid_to_json()` and `text_to_string()` build the fixed bodies of `GET /status/:code`, `GET /json`, `GET /uuid` and `GET /text`.
- `api_view.error_to_json(message)` builds the body of an error answer, for example `{"error":"code must be an integer"}`.

Sent to `/content-type`, the same function returns `Ok(#(200, "application/json"))`, which shows that it sets the header.

## When the server can't start

`server.start` fails when something already listens on the port: another test, a server you forgot to stop, or a program of your own. It returns an error, and `with_mock_server` passes it on. With another server on port 19832, the call from Step 2 returns:

### The error of a port in use <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_getting_started_port_in_use.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
with_mock_server(19832, fetch_greeting)
  -> Error(InitFailed("Port 19832 already in use on localhost. Stop the process using that port or choose a different one."))
```

The message names the port, so a failing test tells you which one to free. `server.start_with_config` fails the same way.

The opposite case is your code, not the server: a request to a port where nothing listens. That's what your code sees when the real service is down, and you can test it without a server at all. `fetch_greeting("http://localhost:19833")` returns:

### The error with no server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_getting_started_no_server.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
Error(RequestFailed("FailedToConnect(Posix(\"econnrefused\"), Posix(\"econnrefused\"))"))
```

The [Test how your client handles failures](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/testing-failures.md) guide goes further: error statuses, timeouts, bodies that aren't text and dropped streams.

## Test your code

Here's a test module for `fetch_greeting` and `post_json`. Each test starts its own server, on its own port, and stops it before the assertion:

### Test the client against the mock server <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_getting_started_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/server
import dream_mock_server/views/api_view
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import snippets/guide_getting_started_greeting.{fetch_greeting}
import snippets/guide_getting_started_post_json.{note_json, post_json}

pub fn tests() -> TestSuite {
  describe("my client", [
    it("fetches the greeting", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_801)

      // Act
      let greeting = fetch_greeting("http://localhost:19801")
      server.stop(mock)

      // Assert
      greeting
      |> should
      |> be_equal(Ok("Hello, World!"))
      |> or_fail_with("Expected the text of /text")
    }),
    it("sends the note as JSON", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_802)

      // Act
      let response =
        post_json("http://localhost:19802/post", note_json("Buy milk"))
      server.stop(mock)

      // Assert
      response
      |> should
      |> be_equal(
        Ok(#(201, api_view.post_to_json("/post", "{\"text\":\"Buy milk\"}"))),
      )
      |> or_fail_with("Expected the server to echo the JSON body")
    }),
    it("sets the JSON content type", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_803)

      // Act
      let response =
        post_json("http://localhost:19803/content-type", note_json("Buy milk"))
      server.stop(mock)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "application/json")))
      |> or_fail_with("Expected the server to echo the content type")
    }),
  ])
}
```

A few things to notice:

- Each test stops the server before it asserts. If the assertion fails, the server is already down.
- If a `let assert` fails and the test process crashes, the server stops anyway, because it stops when the process that started it exits. The next section explains why that matters.
- The second test compares with `api_view.post_to_json` instead of a hand-written string, as Step 3 showed.

## Common pitfalls

**Two tests on one port.** *Symptom:* a test fails with `InitFailed("Port ... already in use on localhost. ...")`, but only sometimes. *Fix:* test runners such as dream_test run tests at the same time. Give each test that starts a server its own port, as the test module above does with 19801, 19802 and 19803.

**Starting the server in another process.** *Symptom:* the server starts, and then every request fails with `econnrefused`. *Fix:* the server stops when the process that called `server.start` exits, even when it exits normally. Call `server.start` in the process that sends the requests, which is the test itself. Don't start it in a process that you spawn and let finish.

**An address in the function.** *Symptom:* the test reaches the real service, or can't run without a network. *Fix:* take the base URL as a parameter, as in [Step 1](#step-1-give-your-code-a-base-url), and pass `http://localhost:<port>` in tests.

**An IPv6 address.** *Symptom:* a request to `http://[::1]:<port>` fails to connect, though the server runs. *Fix:* the server listens on `127.0.0.1` only. Use `localhost` or `127.0.0.1` in the URL.

## Where to go next

- [Test how your client handles failures](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/testing-failures.md): error statuses, slow servers, bodies that aren't text, encodings and broken streams.
- [Stand in for a third-party API](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md): config mode, with your own status and body for each path.
- [Run the server while you develop](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md): a server that runs until you stop it.
- [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md): every built-in endpoint, with its status, headers, body and timing.
- [API reference on HexDocs](https://hexdocs.pm/dream_mock_server/dream_mock_server/server.html): `start`, `start_with_config`, `stop` and the rest of the package.
