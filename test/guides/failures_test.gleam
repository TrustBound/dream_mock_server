//// Tests for the guide "Test how your client handles failures"
//// (docs/guides/testing-failures.md). Each test runs a snippet against a
//// local mock server and asserts the exact value that the guide shows.

import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import gleam/erlang/process
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/result
import snippets/compression_gzip
import snippets/guide_failures_fetch_text.{
  Refused, TimedOut, Unreachable, UnsupportedEncoding, fetch_text,
}
import snippets/guide_failures_gzip_stream

pub fn tests() -> TestSuite {
  describe("failures guide", [
    it("step 1: /text gives the text", fn() {
      // Act
      let fetched = fetch_with_server(19_841, "/text", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Ok("Hello, World!"))
      |> or_fail_with("Expected Hello, World!")
    }),
    it("step 1: /status/503 gives Refused with the body", fn() {
      // Act
      let fetched = fetch_with_server(19_842, "/status/503", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(Refused(status: 503, body: <<"{\"status\":503}">>)))
      |> or_fail_with("Expected Refused 503")
    }),
    it("step 1: /status/404 gives Refused with the body", fn() {
      // Act
      let fetched = fetch_with_server(19_843, "/status/404", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(Refused(status: 404, body: <<"{\"status\":404}">>)))
      |> or_fail_with("Expected Refused 404")
    }),
    it("step 1: /redirect/301 gives Refused with an empty body", fn() {
      // Act
      let fetched = fetch_with_server(19_844, "/redirect/301", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(Refused(status: 301, body: <<>>)))
      |> or_fail_with(
        "Expected Refused 301, because redirects are not followed",
      )
    }),
    it("step 2: /non-utf8-error gives Refused with the bytes", fn() {
      // Act
      let fetched = fetch_with_server(19_845, "/non-utf8-error", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(
        Error(Refused(status: 400, body: <<"Error: ", 192, 193, 254, 255>>)),
      )
      |> or_fail_with("Expected Refused 400 with the bytes")
    }),
    it("step 2: httpc.send loses the status of a body that is not text", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_846)
      let assert Ok(http_request) =
        request.to("http://localhost:19846/non-utf8-error")

      // Act
      let response = httpc.send(http_request)
      server.stop(mock)

      // Assert
      response
      |> should
      |> be_equal(Error(httpc.InvalidUtf8Response))
      |> or_fail_with("Expected InvalidUtf8Response")
    }),
    it("step 3: /slow with a 1000 ms timeout times out", fn() {
      // Act
      let fetched = fetch_with_server(19_847, "/slow", 1000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(TimedOut))
      |> or_fail_with("Expected TimedOut")
    }),
    it("step 3: /stream/slow with a 5000 ms timeout times out", fn() {
      // Act
      let fetched = fetch_with_server(19_848, "/stream/slow", 5000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(TimedOut))
      |> or_fail_with("Expected TimedOut for the whole 10 second stream")
    }),
    it("step 4: a port with no server gives Unreachable", fn() {
      // Act
      let fetched = fetch_text("http://localhost:19849/text", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(Unreachable))
      |> or_fail_with("Expected Unreachable")
    }),
    it("step 5: /identity gives the text", fn() {
      // Act
      let fetched = fetch_with_server(19_850, "/identity", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Ok("Hello, World!"))
      |> or_fail_with("Expected the identity body as it is")
    }),
    it("step 5: /unknown-encoding gives UnsupportedEncoding br", fn() {
      // Act
      let fetched = fetch_with_server(19_851, "/unknown-encoding", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(UnsupportedEncoding("br")))
      |> or_fail_with("Expected br to be refused")
    }),
    it("step 5: /gzip gives UnsupportedEncoding gzip", fn() {
      // Act
      let fetched = fetch_with_server(19_852, "/gzip", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(UnsupportedEncoding("gzip")))
      |> or_fail_with("Expected gzip to be refused")
    }),
    it("step 5: the body of /gzip is gzip_body()", fn() {
      // Act
      let body = raw_body_with_server(19_853, "/gzip")

      // Assert
      body
      |> should
      |> be_equal(Ok(compression_gzip.gzip_body()))
      |> or_fail_with("Expected the gzip bytes of Hello, World!")
    }),
    it("step 5: the body of /stream/gzip is expected_gzip_stream()", fn() {
      // Act
      let body = raw_body_with_server(19_854, "/stream/gzip")

      // Assert
      body
      |> should
      |> be_equal(Ok(guide_failures_gzip_stream.expected_gzip_stream()))
      |> or_fail_with("Expected the joined gzip stream")
    }),
    it("step 6: /stream/error gives Refused 500 with three lines", fn() {
      // Act
      let fetched = fetch_with_server(19_855, "/stream/error", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(
        Error(
          Refused(status: 500, body: <<
            "Error test chunk 1\nError test chunk 2\nError test chunk 3\n",
          >>),
        ),
      )
      |> or_fail_with("Expected Refused 500 with the whole body")
    }),
    it("step 6: gleam_httpc stops the process on /stream/drop", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_856)
      let assert Ok(http_request) =
        request.to("http://localhost:19856/stream/drop")
      let requester =
        process.spawn_unlinked(fn() {
          let _response = httpc.send(http_request)
          Nil
        })
      let monitor = process.monitor(requester)
      let selector =
        process.new_selector()
        |> process.select_specific_monitor(monitor, is_abnormal_exit)

      // Act
      let crashed = process.selector_receive(selector, 5000)
      server.stop(mock)

      // Assert
      crashed
      |> should
      |> be_equal(Ok(True))
      |> or_fail_with("Expected the requesting process to crash")
    }),
    it("step 1: a client that follows redirects gets the text", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_857)
      let assert Ok(http_request) =
        request.to("http://localhost:19857/redirect/chain")

      // Act
      let body =
        httpc.configure()
        |> httpc.follow_redirects(True)
        |> httpc.dispatch(http_request)
        |> result.map(fn(response) { response.body })
      server.stop(mock)

      // Assert
      body
      |> should
      |> be_equal(Ok("Hello, World!"))
      |> or_fail_with("Expected the chain to end at /text")
    }),
    it("step 5: gleam_httpc sends no Accept-Encoding header", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_858)
      let assert Ok(http_request) =
        request.to("http://localhost:19858/echo-accept-encoding")

      // Act
      let body =
        httpc.send(http_request)
        |> result.map(fn(response) { response.body })
      server.stop(mock)

      // Assert
      body
      |> should
      |> be_equal(Ok(""))
      |> or_fail_with("Expected an empty echo")
    }),
  ])
}

fn fetch_with_server(
  port: Int,
  path: String,
  timeout_ms: Int,
) -> Result(String, guide_failures_fetch_text.FetchError) {
  let assert Ok(mock) = server.start(port)
  let fetched =
    fetch_text("http://localhost:" <> int.to_string(port) <> path, timeout_ms)
  server.stop(mock)
  fetched
}

fn raw_body_with_server(port: Int, path: String) -> Result(BitArray, String) {
  let assert Ok(mock) = server.start(port)
  let assert Ok(http_request) =
    request.to("http://localhost:" <> int.to_string(port) <> path)
  let body =
    httpc.send_bits(request.set_body(http_request, <<>>))
    |> result.map(fn(response) { response.body })
    |> result.replace_error("The request failed")
  server.stop(mock)
  body
}

fn is_abnormal_exit(down: process.Down) -> Bool {
  case down {
    process.ProcessDown(reason: process.Abnormal(_), ..) -> True
    _other_down -> False
  }
}
