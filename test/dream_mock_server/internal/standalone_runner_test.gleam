//// Tests of the runner behind `standalone.main`, on free ports.

import dream_mock_server/internal/standalone_runner
import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/http
import fixtures/port
import gleam/erlang/process

pub fn tests() -> TestSuite {
  describe("dream_mock_server/internal/standalone_runner", [
    group("serve_forever", [
      it("serves the built-in endpoints on the port", fn() {
        // Arrange
        let port = port.free_port()
        let runner =
          process.spawn_unlinked(fn() { standalone_runner.serve_forever(port) })

        // Act
        let response = http.get_when_ready(http.url(port, "/text"), 100)
        process.kill(runner)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "Hello, World!")))
        |> or_fail_with("Expected 200 with Hello, World!")
      }),
      it("stops its process with an error when the port is in use", fn() {
        // Arrange
        let port = port.free_port()
        let assert Ok(handle) = server.start(port)
        let runner =
          process.spawn_unlinked(fn() { standalone_runner.serve_forever(port) })
        let monitor = process.monitor(runner)
        let selector =
          process.new_selector()
          |> process.select_specific_monitor(monitor, stopped_with_error)

        // Act
        let result = process.selector_receive(selector, 5000)
        server.stop(handle)

        // Assert
        result
        |> should
        |> be_equal(Ok(True))
        |> or_fail_with("Expected the process to stop with an error")
      }),
    ]),
  ])
}

fn stopped_with_error(down: process.Down) -> Bool {
  case down {
    process.ProcessDown(reason: process.Abnormal(_reason), ..) -> True
    _other_down -> False
  }
}
