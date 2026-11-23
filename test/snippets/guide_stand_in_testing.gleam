//// Guide: Stand in for a third-party API, test your code
////
//// The reader's tests of ask, each against its own stand-in.

import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import snippets/guide_stand_in_ask.{BadReply, RateLimited, ask}
import snippets/guide_stand_in_routes.{
  broken_routes, chat_routes, rate_limited_routes,
}

pub fn tests() -> TestSuite {
  describe("ask", [
    it("returns the text of the first answer", fn() {
      // Arrange
      let assert Ok(stand_in) = server.start_with_config(19_821, chat_routes())

      // Act
      let answer = ask("http://localhost:19821", "test-key", "Say hello")
      server.stop(stand_in)

      // Assert
      answer
      |> should
      |> be_equal(Ok("Hello from the stand-in."))
      |> or_fail_with("Expected the content of the first choice")
    }),
    it("reports a rate limit", fn() {
      // Arrange
      let assert Ok(stand_in) =
        server.start_with_config(19_822, rate_limited_routes())

      // Act
      let answer = ask("http://localhost:19822", "test-key", "Say hello")
      server.stop(stand_in)

      // Assert
      answer
      |> should
      |> be_equal(Error(RateLimited))
      |> or_fail_with("Expected status 429 to be a rate limit")
    }),
    it("reports a body that is not the expected JSON", fn() {
      // Arrange
      let assert Ok(stand_in) =
        server.start_with_config(19_823, broken_routes())

      // Act
      let answer = ask("http://localhost:19823", "test-key", "Say hello")
      server.stop(stand_in)

      // Assert
      answer
      |> should
      |> be_equal(Error(BadReply("upstream connect error")))
      |> or_fail_with("Expected the body to be reported")
    }),
  ])
}
