//// Guide: Run the server while you develop, test your code
////
//// The reader's test of the program that runs the chat API stand-in.

import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import gleam/erlang/process
import snippets/guide_run_dev_stand_in
import snippets/guide_stand_in_ask.{type ChatError, RequestFailed, ask}

pub fn tests() -> TestSuite {
  describe("dev_chat_api", [
    it("answers on port 4010", fn() {
      // Arrange
      let stand_in = process.spawn_unlinked(guide_run_dev_stand_in.main)

      // Act
      let answer = ask_when_ready(20)
      process.kill(stand_in)

      // Assert
      answer
      |> should
      |> be_equal(Ok("Hello from the stand-in."))
      |> or_fail_with("Expected the stand-in to answer")
    }),
  ])
}

/// Asks the stand-in until it answers, at most `attempts` times, 50 ms
/// apart. The program needs a moment to start the server.
fn ask_when_ready(attempts: Int) -> Result(String, ChatError) {
  let answer = ask("http://localhost:4010", "test-key", "Say hello")
  case answer, attempts > 1 {
    Error(RequestFailed(_)), True -> {
      process.sleep(50)
      ask_when_ready(attempts - 1)
    }
    _answer, _last_attempt -> answer
  }
}
