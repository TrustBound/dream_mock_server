//// Tests for the guide "Test how your client handles failures"
//// (docs/guides/testing-failures.md). Each test runs a snippet against a
//// local mock server. A test of an output block compares the real results
//// with the output file that the guide shows. The guide writes each result
//// as Gleam code, with the labels of the fields.

import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/output_file
import gleam/bit_array
import gleam/erlang/process
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import snippets/compression_gzip
import snippets/guide_failures_fetch_text.{type FetchError, Refused, fetch_text}
import snippets/guide_failures_gzip_stream

pub fn tests() -> TestSuite {
  describe("failures guide", [
    it("step 1: the status endpoints give the results of the guide", fn() {
      // Act
      let rows =
        fetch_rows(19_841, [
          #("/text", 2000),
          #("/status/503", 2000),
          #("/status/404", 2000),
          #("/redirect/301", 2000),
        ])

      // Assert
      Ok(output_file.table(rows))
      |> should
      |> be_equal(output_file.read("guide_failures_status_endpoints"))
      |> or_fail_with("Expected the results of the output file")
    }),
    it("step 2: /non-utf8-error gives Refused with the bytes", fn() {
      // Act
      let fetched = fetch_with_server(19_845, "/non-utf8-error", 2000)

      // Assert
      Ok(
        "fetch_text(\".../non-utf8-error\", 2000)\n  -> "
        <> result_literal(fetched)
        <> "\n",
      )
      |> should
      |> be_equal(output_file.read("guide_failures_non_utf8_error"))
      |> or_fail_with("Expected Refused 400 with the bytes of the output file")
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
    it("step 3: the slow endpoints time out", fn() {
      // Act
      let rows = fetch_rows(19_847, [#("/slow", 1000), #("/stream/slow", 5000)])

      // Assert
      Ok(output_file.table(rows))
      |> should
      |> be_equal(output_file.read("guide_failures_slow_endpoints"))
      |> or_fail_with("Expected TimedOut for both, as in the output file")
    }),
    it("step 4: a port with no server gives Unreachable", fn() {
      // Act
      let fetched = fetch_text("http://localhost:19849/text", 2000)

      // Assert
      Ok(
        output_file.table([
          #(
            "fetch_text(\"http://localhost:19849/text\", 2000)",
            result_literal(fetched),
          ),
        ]),
      )
      |> should
      |> be_equal(output_file.read("guide_failures_no_server"))
      |> or_fail_with("Expected Unreachable, as in the output file")
    }),
    it("step 5: the encoding endpoints give the results of the guide", fn() {
      // Act
      let rows =
        fetch_rows(19_850, [
          #("/identity", 2000),
          #("/unknown-encoding", 2000),
          #("/gzip", 2000),
        ])

      // Assert
      Ok(output_file.table(rows))
      |> should
      |> be_equal(output_file.read("guide_failures_encodings"))
      |> or_fail_with("Expected the results of the output file")
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
      Ok(
        "fetch_text(\".../stream/error\", 2000)\n  -> "
        <> result_literal(fetched)
        <> "\n",
      )
      |> should
      |> be_equal(output_file.read("guide_failures_stream_error"))
      |> or_fail_with("Expected Refused 500 with the body of the output file")
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

/// Starts a server on `port`, fetches each path with its timeout, and stops
/// the server. Returns a row for each path: the call as the guide writes it,
/// and the result as Gleam code.
fn fetch_rows(
  port: Int,
  paths: List(#(String, Int)),
) -> List(#(String, String)) {
  let assert Ok(mock) = server.start(port)
  let rows =
    list.map(paths, fn(path) {
      let fetched =
        fetch_text("http://localhost:" <> int.to_string(port) <> path.0, path.1)
      #(
        "fetch_text(\"..." <> path.0 <> "\", " <> int.to_string(path.1) <> ")",
        result_literal(fetched),
      )
    })
  server.stop(mock)
  rows
}

/// Writes a result of `fetch_text` as Gleam code, with the labels of the
/// fields of `Refused`.
fn result_literal(fetched: Result(String, FetchError)) -> String {
  case fetched {
    Ok(text) -> "Ok(" <> string.inspect(text) <> ")"
    Error(Refused(status:, body:)) ->
      "Error(Refused(status: "
      <> int.to_string(status)
      <> ", body: "
      <> bit_array_literal(body)
      <> "))"
    Error(other_error) -> "Error(" <> string.inspect(other_error) <> ")"
  }
}

/// Writes bytes as a Gleam bit array: the longest start that is UTF-8 text
/// as a string, and each byte after it as a number.
fn bit_array_literal(bytes: BitArray) -> String {
  let #(text, rest) = split_text(bytes, bit_array.byte_size(bytes))
  let text_parts = case text {
    "" -> []
    _ -> [string.inspect(text)]
  }
  let byte_parts = list.map(byte_list(rest), int.to_string)
  "<<" <> string.join(list.append(text_parts, byte_parts), ", ") <> ">>"
}

/// Splits `bytes` after the longest start of at most `length` bytes that is
/// UTF-8 text.
fn split_text(bytes: BitArray, length: Int) -> #(String, BitArray) {
  let split = {
    use start <- result.try(bit_array.slice(bytes, 0, length))
    use text <- result.try(bit_array.to_string(start))
    use rest <- result.map(bit_array.slice(
      bytes,
      length,
      bit_array.byte_size(bytes) - length,
    ))
    #(text, rest)
  }
  case split {
    Ok(text_and_rest) -> text_and_rest
    Error(Nil) -> split_text(bytes, length - 1)
  }
}

fn byte_list(bytes: BitArray) -> List(Int) {
  case bytes {
    <<byte, rest:bytes>> -> [byte, ..byte_list(rest)]
    _no_more_bytes -> []
  }
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
