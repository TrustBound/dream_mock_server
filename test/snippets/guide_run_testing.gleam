//// Guide: Run the server while you develop, test your code
////
//// The reader's test of the stand-in that the program runs.

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
