//// Guide: Test how your client handles failures, test your code
////
//// The reader's tests of fetch_text: one test for each kind of failure.

import dream_mock_server/server
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import snippets/guide_failures_fetch_text.{
  Refused, TimedOut, Unreachable, UnsupportedEncoding, fetch_text,
}

pub fn tests() -> TestSuite {
  describe("fetch_text failures", [
    it("reports an error status with its body", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_811)

      // Act
      let fetched = fetch_text("http://localhost:19811/status/503", 2000)
      server.stop(mock)

      // Assert
      fetched
      |> should
      |> be_equal(Error(Refused(status: 503, body: <<"{\"status\":503}">>)))
      |> or_fail_with("Expected status 503 with its body")
    }),
    it("keeps an error body that is not text", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_812)

      // Act
      let fetched = fetch_text("http://localhost:19812/non-utf8-error", 2000)
      server.stop(mock)

      // Assert
      fetched
      |> should
      |> be_equal(
        Error(Refused(status: 400, body: <<"Error: ", 192, 193, 254, 255>>)),
      )
      |> or_fail_with("Expected status 400 with the bytes of the body")
    }),
    it("gives up on a slow server", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_813)

      // Act
      // The server waits 5 seconds before it answers /slow
      let fetched = fetch_text("http://localhost:19813/slow", 1000)
      server.stop(mock)

      // Assert
      fetched
      |> should
      |> be_equal(Error(TimedOut))
      |> or_fail_with("Expected a timeout after 1 second")
    }),
    it("reports a server that is not there", fn() {
      // Arrange
      // Start and stop a server, so that nothing listens on the port
      let assert Ok(mock) = server.start(19_814)
      server.stop(mock)

      // Act
      let fetched = fetch_text("http://localhost:19814/text", 2000)

      // Assert
      fetched
      |> should
      |> be_equal(Error(Unreachable))
      |> or_fail_with("Expected the connection to fail")
    }),
    it("refuses an encoding it cannot read", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_815)

      // Act
      let fetched = fetch_text("http://localhost:19815/unknown-encoding", 2000)
      server.stop(mock)

      // Assert
      fetched
      |> should
      |> be_equal(Error(UnsupportedEncoding("br")))
      |> or_fail_with("Expected the br encoding to be refused")
    }),
  ])
}
