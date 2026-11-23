//// Tests for the getting started guide (docs/guides/getting-started.md).
//// Each test runs a snippet against a local mock server and asserts the
//// exact value that the guide shows.

import dream_mock_server/server
import dream_mock_server/views/api_view
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import fixtures/http
import gleam/erlang/process
import gleam/otp/actor
import gleam/result
import snippets/guide_getting_started_greeting.{RequestFailed, fetch_greeting}
import snippets/programmatic_mode

const refused =
  "FailedToConnect(Posix(\"econnrefused\"), Posix(\"econnrefused\"))"

pub fn tests() -> TestSuite {
  describe("getting started guide", [
    it("step 2: with_mock_server runs fetch_greeting against /text", fn() {
      // Act
      let outcome = programmatic_mode.with_mock_server(19_831, fetch_greeting)

      // Assert
      outcome
      |> should
      |> be_equal(Ok(Ok("Hello, World!")))
      |> or_fail_with("Expected the greeting from the mock server")
    }),
    it("step 2: with_mock_server reports a port that is in use", fn() {
      // Arrange
      let assert Ok(first) = server.start(19_832)

      // Act
      let outcome = programmatic_mode.with_mock_server(19_832, fetch_greeting)
      server.stop(first)

      // Assert
      outcome
      |> should
      |> be_equal(
        Error(actor.InitFailed(
          "Port 19832 already in use on localhost. Stop the process using that port or choose a different one.",
        )),
      )
      |> or_fail_with("Expected the port in use error")
    }),
    it("failures: fetch_greeting with no server reports the refusal", fn() {
      // Act
      let greeting = fetch_greeting("http://localhost:19833")

      // Assert
      greeting
      |> should
      |> be_equal(Error(RequestFailed(refused)))
      |> or_fail_with("Expected the connection to be refused")
    }),
    it("pitfalls: the server stops when its starting process exits", fn() {
      // Arrange
      let started = process.new_subject()
      process.spawn(fn() { process.send(started, server.start(19_834)) })
      let assert Ok(Ok(_handle)) = process.receive(started, 5000)
      process.sleep(200)

      // Act
      let greeting = fetch_greeting("http://localhost:19834")

      // Assert
      greeting
      |> should
      |> be_equal(Error(RequestFailed(refused)))
      |> or_fail_with("Expected the server to stop with its process")
    }),
    it("step 3: the echo of the note is the JSON the guide shows", fn() {
      // Act
      let body = api_view.post_to_json("/post", "{\"text\":\"Buy milk\"}")

      // Assert
      body
      |> should
      |> be_equal(
        "{\"method\":\"POST\",\"url\":\"/post\",\"data\":\"{\\\"text\\\":\\\"Buy milk\\\"}\"}",
      )
      |> or_fail_with("Expected the echo body of the guide")
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
