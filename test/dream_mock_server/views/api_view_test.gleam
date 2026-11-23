import dream_mock_server/views/api_view
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}

pub fn tests() -> TestSuite {
  describe("dream_mock_server/views/api_view", [
    group("get_to_json", [
      it("returns the method, url, query and empty headers", fn() {
        // Act
        let json = api_view.get_to_json("/get", "a=1&b=2")

        // Assert
        json
        |> should
        |> be_equal(
          "{\"method\":\"GET\",\"url\":\"/get\",\"query\":\"a=1&b=2\",\"headers\":[]}",
        )
        |> or_fail_with("Expected the GET echo JSON")
      }),
    ]),
    group("post_to_json", [
      it("returns the method, url and data", fn() {
        // Act
        let json = api_view.post_to_json("/post", "hello")

        // Assert
        json
        |> should
        |> be_equal(
          "{\"method\":\"POST\",\"url\":\"/post\",\"data\":\"hello\"}",
        )
        |> or_fail_with("Expected the POST echo JSON")
      }),
    ]),
    group("put_to_json", [
      it("returns the method, url and data", fn() {
        // Act
        let json = api_view.put_to_json("/put", "hello")

        // Assert
        json
        |> should
        |> be_equal("{\"method\":\"PUT\",\"url\":\"/put\",\"data\":\"hello\"}")
        |> or_fail_with("Expected the PUT echo JSON")
      }),
    ]),
    group("patch_to_json", [
      it("returns the method, url and data", fn() {
        // Act
        let json = api_view.patch_to_json("/patch", "hello")

        // Assert
        json
        |> should
        |> be_equal(
          "{\"method\":\"PATCH\",\"url\":\"/patch\",\"data\":\"hello\"}",
        )
        |> or_fail_with("Expected the PATCH echo JSON")
      }),
    ]),
    group("delete_to_json", [
      it("returns the method and url", fn() {
        // Act
        let json = api_view.delete_to_json("/delete")

        // Assert
        json
        |> should
        |> be_equal("{\"method\":\"DELETE\",\"url\":\"/delete\"}")
        |> or_fail_with("Expected the DELETE JSON")
      }),
    ]),
    group("status_to_json", [
      it("returns the status code", fn() {
        // Act
        let json = api_view.status_to_json(418)

        // Assert
        json
        |> should
        |> be_equal("{\"status\":418}")
        |> or_fail_with("Expected the status JSON")
      }),
    ]),
    group("simple_json_to_string", [
      it("returns the hello message and success flag", fn() {
        // Act
        let json = api_view.simple_json_to_string()

        // Assert
        json
        |> should
        |> be_equal("{\"message\":\"Hello, World!\",\"success\":true}")
        |> or_fail_with("Expected the simple JSON")
      }),
    ]),
    group("uuid_to_json", [
      it("returns the fixed UUID", fn() {
        // Act
        let json = api_view.uuid_to_json()

        // Assert
        json
        |> should
        |> be_equal("{\"uuid\":\"123e4567-e89b-12d3-a456-426614174000\"}")
        |> or_fail_with("Expected the UUID JSON")
      }),
    ]),
    group("text_to_string", [
      it("returns Hello, World!", fn() {
        // Act
        let text = api_view.text_to_string()

        // Assert
        text
        |> should
        |> be_equal("Hello, World!")
        |> or_fail_with("Expected Hello, World!")
      }),
    ]),
    group("error_to_json", [
      it("returns the error message", fn() {
        // Act
        let json = api_view.error_to_json("Something failed")

        // Assert
        json
        |> should
        |> be_equal("{\"error\":\"Something failed\"}")
        |> or_fail_with("Expected the error JSON")
      }),
    ]),
  ])
}
