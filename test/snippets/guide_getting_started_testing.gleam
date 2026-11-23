//// Guide: Getting started, test your code
////
//// The reader's tests of fetch_greeting and post_json, each against its own
//// mock server.

import dream_mock_server/server
import dream_mock_server/views/api_view
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, it}
import snippets/guide_getting_started_greeting.{fetch_greeting}
import snippets/guide_getting_started_post_json.{note_json, post_json}

pub fn tests() -> TestSuite {
  describe("my client", [
    it("fetches the greeting", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_801)

      // Act
      let greeting = fetch_greeting("http://localhost:19801")
      server.stop(mock)

      // Assert
      greeting
      |> should
      |> be_equal(Ok("Hello, World!"))
      |> or_fail_with("Expected the text of /text")
    }),
    it("sends the note as JSON", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_802)

      // Act
      let response =
        post_json("http://localhost:19802/post", note_json("Buy milk"))
      server.stop(mock)

      // Assert
      response
      |> should
      |> be_equal(
        Ok(#(201, api_view.post_to_json("/post", "{\"text\":\"Buy milk\"}"))),
      )
      |> or_fail_with("Expected the server to echo the JSON body")
    }),
    it("sets the JSON content type", fn() {
      // Arrange
      let assert Ok(mock) = server.start(19_803)

      // Act
      let response =
        post_json("http://localhost:19803/content-type", note_json("Buy milk"))
      server.stop(mock)

      // Assert
      response
      |> should
      |> be_equal(Ok(#(200, "application/json")))
      |> or_fail_with("Expected the server to echo the content type")
    }),
  ])
}
