//// Tests of the standalone entry point. It listens on the fixed port 3004.

import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/types.{type TestSuite}
import dream_test/unit.{describe, group, it}
import fixtures/http
import gleam/erlang/process
import standalone

pub fn tests() -> TestSuite(Nil) {
  describe("standalone", [
    group("main", [
      it("serves the built-in endpoints on port 3004", fn() {
        // Arrange
        let server_process = process.spawn_unlinked(standalone.main)

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
