# Run the server while you develop

Tests start and stop the mock server for you. Sometimes you want it running on its own instead: to see with `curl` exactly what an endpoint sends, to watch a stream arrive chunk by chunk, or to point a development build of your app at an API stand-in while you work on the screens that use it. This guide shows the ways to run the server until you stop it, and how to pick one.

## Table of Contents

- [What you'll build](#what-youll-build)
- [Before you start](#before-you-start)
- [Which way to run it](#which-way-to-run-it)
- [Step 1: Run the built-in server](#step-1-run-the-built-in-server)
- [Step 2: Look at what the endpoints send](#step-2-look-at-what-the-endpoints-send)
- [Step 3: Run your own stand-in](#step-3-run-your-own-stand-in)
- [Step 4: Start the built-in server from Gleam](#step-4-start-the-built-in-server-from-gleam)
- [When the port is in use](#when-the-port-is-in-use)
- [Test your code](#test-your-code)
- [Common pitfalls](#common-pitfalls)
- [Where to go next](#where-to-go-next)

## What you'll build

In this guide you'll:

- Run the built-in server on port 3004, and send it requests with `curl`.
- Watch a streaming endpoint send its chunks.
- Write a small program that runs your own API stand-in on a fixed port, for your app to use while you develop.
- Start the built-in server on port 3004 from Gleam code.
- Test the program that runs your stand-in.

## Before you start

For Step 1 and Step 2 you need a clone of this repository, and Gleam and Erlang:

```sh
git clone https://github.com/TrustBound/dream_mock_server.git
cd dream_mock_server
```

For Step 3 and Step 4 you need the package in your own project, as in [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md):

```sh
gleam add --dev dream_mock_server
```

The examples use `curl`. Any HTTP client works.

## Which way to run it

| Your situation | Use | Why |
|:---|:---|:---|
| You want to try the built-in endpoints by hand | `make run` in a clone | No code to write. The server listens on port 3004. |
| Your app needs an API stand-in while you develop it | A `main` of your own that calls `server.start_with_config` | Your routes, on the port your app's configuration names. |
| Your own program or script needs the built-in server on port 3004 | `standalone.main` in a new process | The same server as `make run`, started from Gleam. |
| A test needs the server | `server.start` and `server.stop` in the test | The [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md) guide shows how. A test shouldn't depend on a server you started by hand. |

## Step 1: Run the built-in server

From the root of the clone:

```sh
make run
```

`make run` runs `gleam run -m standalone`, which calls `standalone.main`. That starts the server with every built-in endpoint on `localhost` port 3004, prints `Listening on http://127.0.0.1:3004`, and doesn't return. The server runs until you stop the program with Ctrl+C.

## Step 2: Look at what the endpoints send

In a second terminal, send some requests:

```sh
curl -i http://localhost:3004/json
curl "http://localhost:3004/get?page=2"
curl -X POST -d 'hello' http://localhost:3004/post
```

The first one shows the status line, the headers and the body `{"message":"Hello, World!","success":true}`. The second echoes the path and the query: `{"method":"GET","url":"/get","query":"page=2","headers":[]}`. The third echoes the body with status 201: `{"method":"POST","url":"/post","data":"hello"}`. A path with no endpoint, such as `/nope`, gets status 404 with the body `Route not found`.

To see a stream arrive, turn off the output buffer of `curl` with `-N`:

```sh
curl -N http://localhost:3004/stream/slow
```

The lines `Chunk 1` to `Chunk 5` appear one at a time, 2 seconds apart. `/stream/fast` does the same with 10 lines, 100 ms apart.

`curl http://localhost:3004/` shows a text page that lists every built-in endpoint, with its method, its path and what it returns. The server makes this page from the same table that it uses to answer requests, so the page names each endpoint that answers. The [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md) also gives the headers, bodies and timing. In Gleam, `index_view.format_index()` from `dream_mock_server/views/index_view` returns the same page as `GET /`.

## Step 3: Run your own stand-in

Your app is easier to work on when the API it calls answers fast, the same way each time, and without a key. If you already have stand-in routes for your tests, as in [Stand in for a third-party API](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md), run them as a program too. This module starts a stand-in with the chat routes of that guide on port 4010, and keeps it running. The start is in its own function, `start`, so a test can call it too:

### Run an API stand-in until you stop it <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_run_dev_stand_in.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/server
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import gleam/string
import snippets/guide_stand_in_routes

/// Starts the chat API stand-in on http://localhost:4010. Returns when the
/// stand-in answers requests.
pub fn start() -> Result(server.ServerHandle, actor.StartError) {
  server.start_with_config(4010, guide_stand_in_routes.chat_routes())
}

/// Runs the chat API stand-in until you stop it.
pub fn main() -> Nil {
  case start() {
    Ok(_handle) -> {
      io.println("Chat API stand-in on http://localhost:4010")
      process.sleep_forever()
    }
    Error(start_error) ->
      io.println_error(
        "Cannot start the stand-in: " <> string.inspect(start_error),
      )
  }
}
```

Put the module in your project's `test/` directory, for example as `test/dev_chat_api.gleam`. Code in `test/` can use dev dependencies, and it never ships with your package. Then run it by its module name:

```sh
gleam run -m dev_chat_api
```

Here's what it does:

- `start` calls `server.start_with_config`, which returns a handle when the stand-in answers requests.
- `process.sleep_forever()` keeps the process alive. This matters: the server stops when the process that started it exits, so a `main` that returns stops its own server.
- If the port is taken, the program prints the start error and ends, instead of crashing.

Now point your app's configuration at `http://localhost:4010` and run it. Or try the stand-in by hand:

```sh
curl -X POST http://localhost:4010/v1/chat/completions
```

It answers status 200 with the reply from the routes, which holds `Hello from the stand-in.`. A GET to the same path gets `404` with `Not found`, because the route only matches POST.

## Step 4: Start the built-in server from Gleam

To get the server of `make run` from Gleam, for example in a script that runs a demo, call `standalone.main` in a new process:

### Run the server in a new process <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/standalone_main.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import gleam/erlang/process
import standalone

/// Runs the mock server on port 3004 in a new process. Kill the process to
/// stop the server.
pub fn start_in_background() -> process.Pid {
  process.spawn_unlinked(standalone.main)
}
```

`standalone.main` never returns while the server runs, so it needs its own process. Use `process.spawn_unlinked`, so the server process doesn't stop when the process that spawned it stops. To stop the server, kill the process with `process.kill(pid)`.

For anything other than port 3004, call `server.start(port)` and keep the process alive, as in Step 3.

## When the port is in use

Only one program can listen on a port. When another program already uses port 3004, `make run` stops with a panic, and the message names the port:

```text
The mock server cannot start on port 3004: InitFailed("Port 3004 already in use on localhost. Stop the process using that port or choose a different one.")
```

Often the other program is an earlier `make run` that's still running in another terminal. To find it, run `lsof -nP -iTCP:3004 -sTCP:LISTEN`, which shows the process that listens on the port.

The stand-in from Step 3 reports the same error with `Cannot start the stand-in:` and returns, instead of a panic.

## Test your code

A program that runs forever still needs a test, so you know it starts and serves the right routes. Don't test it by running `main` in another process and sending requests until one works. Until `start` returns, the server isn't ready, and a request in that time can get a closed connection, not a refused one. `gleam_httpc` raises an exception on a closed connection, so such a test crashes now and then. Test `start` instead. It returns when the stand-in answers, so the test sends one request and needs no wait:

### Test the program that runs the stand-in <a href="https://github.com/TrustBound/dream_mock_server/blob/2.0.0/test/snippets/guide_run_testing.gleam"><img align="right" alt="Tested snippet" src="https://img.shields.io/badge/%F0%9F%A7%AA_tested-snippet-lightgreen.svg?style=flat-square"></a>

```gleam
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import snippets/guide_run_dev_stand_in
import snippets/guide_stand_in_ask.{ask}

pub fn tests() -> TestSuite {
  describe("dev_chat_api", [
    it("answers on port 4010", fn() {
      // Arrange
      // start returns when the stand-in answers, so no wait is needed
      let assert Ok(stand_in) = guide_run_dev_stand_in.start()

      // Act
      let answer = ask("http://localhost:4010", "test-key", "Say hello")
      server.stop(stand_in)

      // Assert
      answer
      |> should
      |> be_equal(Ok("Hello from the stand-in."))
      |> or_fail_with("Expected the stand-in to answer")
    }),
  ])
}
```

`main` adds only the print and `process.sleep_forever()` to `start`, so this test covers what can go wrong in it: the port and the routes.

The stand-in uses the fixed port 4010, so only one test may start it at a time. If another program uses port 4010 while the test runs, `start` returns an error and the `let assert` fails.

## Common pitfalls

**Sending requests while the server starts.** *Symptom:* a test that starts the server in another process, then sends requests until one works, fails now and then with `socket_closed_remotely`. *Fix:* the port opens a moment before the server can answer, and a request in that moment gets a closed connection. Wait for `server.start` or `server.start_with_config` to return, as the test above does with `start`, before you send a request.

**A `main` that returns.** *Symptom:* the program prints that the server listens, and then exits, and every request fails. *Fix:* the server stops when its process exits. End `main` with `process.sleep_forever()`.

**Another machine or a container.** *Symptom:* `curl` works on your machine, but a phone, another computer or a Docker container can't connect. *Fix:* the server listens on `127.0.0.1` only, so only programs on the same machine can reach it. Run the program that sends the requests on the same machine, outside a container.

**An old server on the port.** *Symptom:* `make run` stops with `already in use`, or your requests get answers you didn't expect. *Fix:* another server still runs on the port. Find it with `lsof -nP -iTCP:<port> -sTCP:LISTEN` and stop it.

**Tests that need the running server.** *Symptom:* tests pass on your machine and fail in CI. *Fix:* a test must start its own server with `server.start` or `server.start_with_config`, on its own port. Keep the running server for work by hand.

## Where to go next

- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): start and stop the server inside your tests.
- [Stand in for a third-party API](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/stand-in-for-an-api.md): write the routes for the stand-in of Step 3.
- [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md): every built-in endpoint, with its status, headers, body and timing.
- [API reference on HexDocs](https://hexdocs.pm/dream_mock_server/standalone.html): `standalone.main` and the rest of the package.
