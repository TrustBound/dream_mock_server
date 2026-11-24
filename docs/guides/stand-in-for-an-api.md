# Stand in for a third-party API

Your code calls someone else's API: a chat completion API, a payment provider, a weather service. Your tests shouldn't. The real API costs money for each call, needs a key in your CI, answers differently each time, and won't send you a rate limit or a 500 when you ask for one. Config mode turns the mock server into a stand-in for that API: you list the paths, and the status and body that each one answers. This guide builds a client for a chat completion API and tests it against a stand-in, including the ways the real API fails.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Step 1: Write a client that takes the base URL](#step-1-write-a-client-that-takes-the-base-url)
- [Step 2: Give the stand-in its routes](#step-2-give-the-stand-in-its-routes)
- [Step 3: Make it fail the way the real API fails](#step-3-make-it-fail-the-way-the-real-api-fails)
- [Step 4: Serve more than one route](#step-4-serve-more-than-one-route)
- [How a request finds its route](#how-a-request-finds-its-route)
- [What config mode doesn't do](#what-config-mode-doesnt-do)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Write a client function for a chat completion API that sends a question and returns the answer.
- Start a stand-in that answers it with a fixed reply.
- Start stand-ins that answer with a rate limit, a server error, and a body that isn't JSON.
- Serve several paths and methods from one stand-in, in the right order.
- Test each case, one stand-in for each test.

## Before you start

You need the dev dependencies from [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): `dream_mock_server`, `dream_test` and `gleam_httpc`. The client in this guide also builds and reads JSON with `gleam_json`. Add it if your project doesn't have it yet:

```sh
gleam add gleam_json
gleam add --dev dream_mock_server gleam_httpc
```

The API in this guide is shaped like a typical chat completion API: a POST to `/v1/chat/completions` with a list of messages, and an answer with a list of `choices`. The mock server has no built-in knowledge of any provider. Everything the stand-in answers comes from the routes you give it, so the same steps work for any HTTP API.

## Step 1: Write a client that takes the base URL

The client is your code, and it's the same in production and in tests. It takes the base URL as a parameter, as in [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md#step-1-give-your-code-a-base-url). In production that's the URL of the real API. In a test it's `http://localhost:<port>`:

### Ask a chat completion API a question <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_stand_in_ask.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import gleam/string

pub type ChatError {
  /// The URL is not valid.
  BadUrl(url: String)
  /// The request did not get a response.
  RequestFailed(reason: String)
  /// The API answered with status 429: too many requests.
  RateLimited
  /// The API answered with another status that is not 200.
  ApiError(status: Int, body: String)
  /// The API answered 200, but the body is not the JSON this code expects.
  BadReply(body: String)
}

/// Sends one question to the chat completion API at `base_url` and returns
/// the text of the first answer.
pub fn ask(
  base_url: String,
  api_key: String,
  question: String,
) -> Result(String, ChatError) {
  let url = base_url <> "/v1/chat/completions"
  use http_request <- result.try(
    request.to(url) |> result.replace_error(BadUrl(url)),
  )
  let http_request =
    http_request
    |> request.set_method(http.Post)
    |> request.set_header("authorization", "Bearer " <> api_key)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(question_json(question))
  use response <- result.try(
    httpc.send(http_request)
    |> result.map_error(fn(error) { RequestFailed(string.inspect(error)) }),
  )
  case response.status {
    200 -> first_answer(response.body)
    429 -> Error(RateLimited)
    status -> Error(ApiError(status: status, body: response.body))
  }
}

fn question_json(question: String) -> String {
  json.object([
    #("model", json.string("example-model")),
    #(
      "messages",
      json.preprocessed_array([
        json.object([
          #("role", json.string("user")),
          #("content", json.string(question)),
        ]),
      ]),
    ),
  ])
  |> json.to_string
}

fn first_answer(body: String) -> Result(String, ChatError) {
  let answers_decoder =
    decode.at(
      ["choices"],
      decode.list(decode.at(["message", "content"], decode.string)),
    )
  case json.parse(body, answers_decoder) {
    Ok([answer, ..]) -> Ok(answer)
    Ok([]) | Error(_) -> Error(BadReply(body))
  }
}
```

Here's what it does:

- `ask` sends the question as JSON, with an API key in the `authorization` header.
- On status 200, `first_answer` decodes `choices[].message.content` and returns the first one.
- Status 429 becomes `RateLimited`, because that's the one error your program handles in its own way: wait, then try again. Every other status becomes `ApiError` with the body, so you can log what the API said.
- A 200 with a body that doesn't decode becomes `BadReply` with the body. That happens more than you'd think, for example when a proxy answers in place of the API.

Each error case is a branch that the real API almost never takes on your machine. The next steps make the stand-in take them.

## Step 2: Give the stand-in its routes

A stand-in is a list of `MockRoute` values. Each one names a path, how the path matches, a method, and the status and body of the answer. This module holds the routes for this guide:

### Routes for a chat completion stand-in <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_stand_in_routes.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/config.{type MockRoute, Exact, MockRoute}
import gleam/http.{Post}
import gleam/option.{Some}

/// A chat completion API that answers every question with the same text.
pub fn chat_routes() -> List(MockRoute) {
  [
    MockRoute(
      path: "/v1/chat/completions",
      path_match: Exact,
      method: Some(Post),
      status: 200,
      body: "{\"id\":\"chatcmpl-1\",\"object\":\"chat.completion\","
        <> "\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\","
        <> "\"content\":\"Hello from the stand-in.\"},\"finish_reason\":\"stop\"}]}",
    ),
  ]
}

/// A chat completion API that refuses every question: too many requests.
pub fn rate_limited_routes() -> List(MockRoute) {
  [
    MockRoute(
      path: "/v1/chat/completions",
      path_match: Exact,
      method: Some(Post),
      status: 429,
      body: "{\"error\":{\"message\":\"Rate limit reached\"}}",
    ),
  ]
}

/// A chat completion API that answers 200 with a body that is not JSON.
pub fn broken_routes() -> List(MockRoute) {
  [
    MockRoute(
      path: "/v1/chat/completions",
      path_match: Exact,
      method: Some(Post),
      status: 200,
      body: "upstream connect error",
    ),
  ]
}
```

`chat_routes()` has one route: a POST to exactly `/v1/chat/completions` answers status 200 with a body in the shape of the real API. Start a server with it, and point `ask` at the server:

### The reply of the stand-in <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_stand_in_ask.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
server.start_with_config(19876, chat_routes())
ask("http://localhost:19876", "test-key", "Say hello")
  -> Ok("Hello from the stand-in.")
```

Here's what the fields of a `MockRoute` do:

- `path`: the path to match, without the query string.
- `path_match`: `Exact` to match that path only, or `Prefix` to match every path that starts with it.
- `method`: `Some(Post)` to match only POST requests, or `None` to match every method. The methods come from `gleam/http`.
- `status` and `body`: the answer. The body is sent as it is.

Copy a real answer of the API into `body`, from its documentation or from a request you made by hand. Your decoder then runs against the shape that the API really sends, and not against the shape you remember.

## Step 3: Make it fail the way the real API fails

The routes of a server are fixed when it starts. To test a failure, start a stand-in whose routes fail. `rate_limited_routes()` and `broken_routes()` in the module above answer the same path with a 429 and with a body that isn't JSON. A route with status 500 works the same way:

### The errors of the failing routes <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_stand_in_failing_routes.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
ask against rate_limited_routes()  -> Error(RateLimited)
ask against broken_routes()        -> Error(BadReply("upstream connect error"))
ask against a 500 route            -> Error(ApiError(status: 500, body: "{\"error\":{\"message\":\"Internal error\"}}"))
```

One stand-in for each scenario keeps each test simple: the test names the scenario in its routes, and nothing else can change the answer. The tests start each stand-in on its own port, so they can run at the same time.

## Step 4: Serve more than one route

A real client often calls more than one endpoint of an API, or the same path with two methods. A stand-in can hold as many routes as you need. These routes give a different answer to GET and POST on the same path:

### Routes for one path with two methods <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_method_specific.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

`GET /resource` answers `200` with `{"ok":true}`, `POST /resource` answers `201` with `{"created":true}`, and any other method on that path gets `404` with the body `Not found`.

When routes overlap, order matters. The server checks the routes in list order and the first one that matches wins. So put a specific route before a broad `Prefix` route that also matches its path:

### A specific route before a prefix route <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_ordering.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

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

With these routes:

### The answers of the routes <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/outputs/guide_stand_in_route_order.txt"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```text
GET /api/special          -> 200 "special"
GET /api/users            -> 200 "general"
GET /apiary               -> 200 "general"
GET /api/special?debug=1  -> 200 "special"
```

If the `Prefix` route came first, `/api/special` would answer `general` too. The third line is a surprise for most people: `Prefix` compares text, not path segments, so `/api` also matches `/apiary`. End a prefix with `/` (for example `/api/`) to match only the paths below it.

## How a request finds its route

The rules in one place:

| Request | Answer |
|:---|:---|
| Matches the path and method of a route | The `status` and `body` of the first such route, in list order |
| Matches the path of a route, but not its method | `404` with the body `Not found`, unless a later route matches |
| Matches no route | `404` with the body `Not found` |
| Method HEAD | Matched as any other method is. The answer has the headers of the route, with its `content-length`, and no body |
| Method OPTIONS | Matched as any other method is |
| Method CONNECT, TRACE, or a method that isn't standard, such as `PURGE` | Matched with that method, as any other method is |

A few details of the path match:

- The query string isn't part of the path, so `Exact` with `/api/special` matches `/api/special?debug=1`.
- `Exact` compares the whole path, so `/resource` doesn't match `/resource/`.

A route with `None` matches every method, HEAD and OPTIONS included. A route with `Some(http.Get)` doesn't match HEAD. To answer HEAD, give a route with `Some(http.Head)` or `None`.

A route with `Some(http.Options)` answers an OPTIONS request, for example a CORS preflight. A status 204 goes out with no body and no `content-length`:

### Routes that answer a CORS preflight <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_cors_preflight.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/config.{type MockRoute, Exact, MockRoute}
import gleam/http.{Get, Options}
import gleam/option.{Some}

// OPTIONS /api/items -> 204 with no body
// GET /api/items     -> 200 []
// HEAD /api/items    -> 404 Not found (no route for HEAD)
pub fn preflight_routes() -> List(MockRoute) {
  [
    MockRoute("/api/items", Exact, Some(Options), 204, ""),
    MockRoute("/api/items", Exact, Some(Get), 200, "[]"),
  ]
}
```

A route can't add headers, so the 204 has no `Access-Control-Allow-Origin` header. A browser refuses that preflight. A client that sends OPTIONS and reads the status gets the 204.

The server never changes a method into another method. A route with `Some(http.Trace)` matches only a TRACE request. For a method that isn't standard, give its name to `http.Other`. The name is case-sensitive, so `Other("PURGE")` matches `PURGE` and not `Purge`:

### A route for a method that isn't standard <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/config_mode_custom_method.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/config.{type MockRoute, Exact, MockRoute}
import gleam/http.{Other}
import gleam/option.{Some}

// PURGE /cache -> 200 purged
// GET /cache   -> 404 Not found
// Purge /cache -> 404 Not found (a method name is case-sensitive)
pub fn cache_routes() -> List(MockRoute) {
  [MockRoute("/cache", Exact, Some(Other("PURGE")), 200, "purged")]
}
```

## What config mode doesn't do

Config mode answers with fixed text, and that's all it does. Know these limits before you build on it:

- **Every answer has `Content-Type: text/plain; charset=utf-8`.** The body of `chat_routes()` is JSON, but the header says text. A client that checks for `application/json` before it decodes refuses it. Test that check in your client with a built-in endpoint instead, such as `GET /json`, which answers with `application/json`.
- **No streaming.** The body is sent in one piece. To test a client that streams, use the built-in streaming endpoints, such as `GET /stream/json`, with `server.start`.
- **No record of requests.** The stand-in doesn't keep the requests it got, and it doesn't check headers or the body. It answers a request without the `authorization` header just the same. To check what your client sends, use the echo endpoints of the built-in server, as in [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md#step-3-check-what-your-code-sends).
- **No built-in endpoints.** A config mode server serves only your routes. `GET /text` on it gets `404` with `Not found`, unless one of your routes matches it.
- **No headers of your own.** A route sets the status and the body only. A CORS preflight gets the 204 of its route, but no `Access-Control-Allow-*` header, so a browser refuses it.
- **Routes are fixed at start.** To change the answers, stop the server and start one with other routes.

## Test your code

Here's a test module for `ask`, one test for each scenario:

### Test ask against three stand-ins <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_stand_in_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import snippets/guide_stand_in_ask.{BadReply, RateLimited, ask}
import snippets/guide_stand_in_routes.{
  broken_routes, chat_routes, rate_limited_routes,
}

pub fn tests() -> TestSuite {
  describe("ask", [
    it("returns the text of the first answer", fn() {
      // Arrange
      let assert Ok(stand_in) = server.start_with_config(19_821, chat_routes())

      // Act
      let answer = ask("http://localhost:19821", "test-key", "Say hello")
      server.stop(stand_in)

      // Assert
      answer
      |> should
      |> be_equal(Ok("Hello from the stand-in."))
      |> or_fail_with("Expected the content of the first choice")
    }),
    it("reports a rate limit", fn() {
      // Arrange
      let assert Ok(stand_in) =
        server.start_with_config(19_822, rate_limited_routes())

      // Act
      let answer = ask("http://localhost:19822", "test-key", "Say hello")
      server.stop(stand_in)

      // Assert
      answer
      |> should
      |> be_equal(Error(RateLimited))
      |> or_fail_with("Expected status 429 to be a rate limit")
    }),
    it("reports a body that is not the expected JSON", fn() {
      // Arrange
      let assert Ok(stand_in) =
        server.start_with_config(19_823, broken_routes())

      // Act
      let answer = ask("http://localhost:19823", "test-key", "Say hello")
      server.stop(stand_in)

      // Assert
      answer
      |> should
      |> be_equal(Error(BadReply("upstream connect error")))
      |> or_fail_with("Expected the body to be reported")
    }),
  ])
}
```

Each test starts the stand-in for its scenario, calls `ask`, stops the stand-in, and asserts the whole result. The API key is `test-key`, because the stand-in doesn't check it, and a real key has no place in a test.

## Common pitfalls

**A broad prefix first.** *Symptom:* a specific route never answers, and a general one answers in its place. *Fix:* the first route that matches wins. Put `Exact` routes and longer prefixes before shorter prefixes.

**A prefix without a slash.** *Symptom:* a request to `/apiary` or `/v1/chat/completions-legacy` gets an answer meant for another path. *Fix:* `Prefix` compares text. End the prefix with `/` to match only the paths below it.

**A content type check in the client.** *Symptom:* the client works against the real API, but refuses every answer of the stand-in. *Fix:* config mode always sends `text/plain; charset=utf-8`. Accept that in tests, or test the check against `GET /json` of the built-in server.

**A test that needs the request.** *Symptom:* you want to assert the JSON your client sent to the stand-in, and there's no way to get it. *Fix:* config mode keeps no record. Send the same request to `POST /post` of the built-in server, which echoes the body, as in [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md#step-3-check-what-your-code-sends).

**A 404 for HEAD.** *Symptom:* a GET request gets your route's answer, but a HEAD request to the same path gets `404`. *Fix:* a route with `Some(http.Get)` matches only GET. Use `None`, or add a route with `Some(http.Head)`.

## Where to go next

- [Run the server while you develop](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md): run this stand-in on a fixed port, and point your app at it by hand.
- [Test how your client handles failures](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/testing-failures.md): timeouts, bodies that aren't text, encodings and broken streams, with the built-in endpoints.
- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): the built-in server and the echo endpoints.
- [API reference on HexDocs](https://hexdocs.pm/dream_mock_server/dream_mock_server/config.html): `MockRoute`, `PathMatch` and `server.start_with_config`.
