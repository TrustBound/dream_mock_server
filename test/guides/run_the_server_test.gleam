//// Tests for the guide "Run the server while you develop"
//// (docs/guides/run-the-server.md). The tests run the `curl` scripts of the
//// guide against a server that they started, and compare what the scripts
//// print with the output files that the guide shows.
////
//// The tests use the fixed ports of the guide, 3004 and 4010. The suites of
//// a run go one after the other, so the other tests on these ports, in
//// `standalone_test` and the readers' test of this guide, can't run at the
//// same time. In this suite, the test of the port in use is in a group,
//// which starts after the other tests stopped their servers.

import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/output_file
import gleam/dynamic/decode
import gleam/erlang/atom
import gleam/erlang/process
import gleam/list
import gleam/result
import gleam/string
import snippets/guide_run_dev_stand_in
import snippets/standalone_main

/// The `date` header of the output file. The real header holds the time of
/// the request, so the test puts this line in its place.
const shown_date = "date: Mon, 23 Nov 2026 19:43:13 GMT"

pub fn tests() -> TestSuite {
  describe("run the server guide", [
    it("step 2: the requests to the built-in server print the guide", fn() {
      // Arrange
      let assert Ok(mock) = server.start(3004)

      // Act
      let #(exit_status, printed) =
        output_file.run_script("scripts/try-the-built-in-server.sh")
      server.stop(mock)

      // Assert
      Ok(#(exit_status, with_shown_date(printed)))
      |> should
      |> be_equal(
        output_file.read("guide_run_the_server_built_in")
        |> result.map(fn(shown) { #(0, shown) }),
      )
      |> or_fail_with("Expected the output file of the requests")
    }),
    it("step 3: the request to the stand-in prints the guide", fn() {
      // Arrange
      let assert Ok(stand_in) = guide_run_dev_stand_in.start()

      // Act
      let printed = output_file.run_script("scripts/try-the-stand-in.sh")
      server.stop(stand_in)

      // Assert
      Ok(printed)
      |> should
      |> be_equal(
        output_file.read("guide_run_the_server_stand_in")
        |> result.map(fn(shown) { #(0, shown) }),
      )
      |> or_fail_with("Expected the output file of the request")
    }),
    group("when the port is in use", [
      it("standalone.main stops with the message of the guide", fn() {
        // Arrange
        let assert Ok(mock) = server.start(3004)
        let runner = standalone_main.start_in_background()
        let monitor = process.monitor(runner)
        let selector =
          process.new_selector()
          |> process.select_specific_monitor(monitor, panic_message)

        // Act
        let message = process.selector_receive(selector, 5000)
        server.stop(mock)

        // Assert
        message
        |> result.map(fn(text) { text <> "\n" })
        |> result.replace_error("The process did not stop")
        |> should
        |> be_equal(output_file.read("guide_run_the_server_port_in_use"))
        |> or_fail_with("Expected the panic message of the output file")
      }),
    ]),
  ])
}

/// Turns the line breaks of the HTTP headers into plain line breaks, as a
/// terminal shows them, and puts the `date` header of the output file in
/// place of the real one.
fn with_shown_date(printed: String) -> String {
  printed
  |> string.replace("\r\n", "\n")
  |> string.split("\n")
  |> list.map(fn(line) {
    case string.starts_with(line, "date: ") {
      True -> shown_date
      False -> line
    }
  })
  |> string.join("\n")
}

/// The message of the panic that stopped a process.
fn panic_message(down: process.Down) -> String {
  case down {
    process.ProcessDown(reason: process.Abnormal(reason), ..) ->
      decode.run(reason, reason_decoder())
      |> result.unwrap("No panic message in " <> string.inspect(reason))
    other_down -> "The process stopped with " <> string.inspect(other_down)
  }
}

/// Decodes the exit reason of a panic: a tuple of the error map of Gleam
/// and the stack trace.
fn reason_decoder() -> decode.Decoder(String) {
  let error_decoder = {
    use message <- decode.field(atom.create("message"), decode.string)
    decode.success(message)
  }
  use message <- decode.field(0, error_decoder)
  decode.success(message)
}
