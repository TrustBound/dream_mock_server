//// Tests of the standalone entry point. It listens on the fixed port 3004.
////
//// The test runs the `standalone_main` snippet. It is the only test that
//// uses port 3004, so the parallel tests cannot collide on the port.

import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/http
import gleam/erlang/process
import snippets/standalone_main

pub fn tests() -> TestSuite {
  describe("standalone", [
    group("main", [
      it("serves the built-in endpoints on port 3004", fn() {
        // Arrange
        let server_process = standalone_main.start_in_background()

        // Act
        let response = http.get_when_ready(http.url(3004, "/text"), 100)
        process.kill(server_process)

        // Assert
        response
        |> should
        |> be_equal(Ok(#(200, "Hello, World!")))
        |> or_fail_with("Expected 200 with Hello, World! on port 3004")
      }),
    ]),
  ])
}
