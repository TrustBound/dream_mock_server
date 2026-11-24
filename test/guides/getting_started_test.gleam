//// Tests for the getting started guide (docs/guides/getting-started.md).
//// Each test runs a snippet against a local mock server. A test of an
//// output block compares the real value with the output file that the
//// guide shows.

import dream_mock_server/server
import dream_mock_server/views/api_view
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/http
import fixtures/output_file
import gleam/erlang/process
import gleam/result
import gleam/string
import snippets/guide_getting_started_greeting.{RequestFailed, fetch_greeting}
import snippets/guide_getting_started_post_json.{note_json, post_json}
import snippets/programmatic_mode

const refused =
  "FailedToConnect(Posix(\"econnrefused\"), Posix(\"econnrefused\"))"

pub fn tests() -> TestSuite {
  describe("getting started guide", [
    it("step 2: with_mock_server runs fetch_greeting against /text", fn() {
      // Act
      let outcome = programmatic_mode.with_mock_server(19_831, fetch_greeting)

      // Assert
      Ok(
        "with_mock_server(19831, fetch_greeting)\n  -> "
        <> string.inspect(outcome)
        <> "\n",
      )
      |> should
      |> be_equal(output_file.read("guide_getting_started_with_mock_server"))
      |> or_fail_with("Expected the greeting of the output file")
    }),
    it("step 2: with_mock_server reports a port that is in use", fn() {
      // Arrange
      let assert Ok(first) = server.start(19_832)

      // Act
      let outcome = programmatic_mode.with_mock_server(19_832, fetch_greeting)
      server.stop(first)

      // Assert
      Ok(
        "with_mock_server(19832, fetch_greeting)\n  -> "
        <> string.inspect(outcome)
        <> "\n",
      )
      |> should
      |> be_equal(output_file.read("guide_getting_started_port_in_use"))
      |> or_fail_with("Expected the port in use error of the output file")
    }),
    it("failures: fetch_greeting with no server reports the refusal", fn() {
      // Act
      let greeting = fetch_greeting("http://localhost:19833")

      // Assert
      Ok(string.inspect(greeting) <> "\n")
      |> should
      |> be_equal(output_file.read("guide_getting_started_no_server"))
      |> or_fail_with("Expected the refusal of the output file")
    }),
    it("pitfalls: the server stops when its starting process exits", fn() {
      // Arrange
      let started = process.new_subject()
      process.spawn(fn() { process.send(started, server.start(19_834)) })
      let assert Ok(Ok(_handle)) = process.receive(started, 5000)
      // The server shuts down after the starting process exits. A request
      // during the shutdown can get a closed connection, which makes
      // gleam_httpc raise, so wait with a client that returns every
      // failure as an Error.
      let assert Error("econnrefused") =
        get_until_refused("http://localhost:19834/text", 100)

      // Act
      let greeting = fetch_greeting("http://localhost:19834")

      // Assert
      greeting
      |> should
      |> be_equal(Error(RequestFailed(refused)))
      |> or_fail_with("Expected the server to stop with its process")
    }),
    it("step 3: post_json gets the echo of the note", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_875)

      // Act
      let posted =
        post_json("http://localhost:19875/post", note_json("Buy milk"))
      server.stop(mock)

      // Assert
      posted
      |> result.map(fn(answer) { #(answer.0, answer.1 <> "\n") })
      |> should
      |> be_equal(
        output_file.read("guide_getting_started_note_echo")
        |> result.map(fn(body) { #(201, body) }),
      )
      |> or_fail_with("Expected status 201 and the echo of the output file")
    }),
    it("step 3: api_view builds the echo of the note", fn() {
      // Act
      let body = api_view.post_to_json("/post", "{\"text\":\"Buy milk\"}")

      // Assert
      Ok(body <> "\n")
      |> should
      |> be_equal(output_file.read("guide_getting_started_note_echo"))
      |> or_fail_with("Expected the echo body of the output file")
    }),
    it("pitfalls: the server does not listen on the IPv6 loopback", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_835)

      // Act
      let failed = http.get("http://[::1]:19835/text") |> result.is_error
      server.stop(mock)

      // Assert
      failed
      |> should
      |> be_equal(True)
      |> or_fail_with("Expected the IPv6 request to fail")
    }),
  ])
}

/// Sends GET requests until the connection is refused, at most `attempts`
/// times, 50 ms apart. Returns the last result.
fn get_until_refused(
  url: String,
  attempts: Int,
) -> Result(#(Int, String), String) {
  case http.get(url), attempts > 1 {
    Error("econnrefused"), _more_attempts -> Error("econnrefused")
    _still_up, True -> {
      process.sleep(50)
      get_until_refused(url, attempts - 1)
    }
    last_result, False -> last_result
  }
}
