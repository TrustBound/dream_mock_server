import dream_mock_server/internal/path
import dream_test/matchers.{be_equal, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}

pub fn tests() -> TestSuite {
  describe("dream_mock_server/internal/path", [
    segments_tests(),
    strip_extension_tests(),
  ])
}

fn segments_tests() {
  group("segments", [
    it("splits a path into its segments", fn() {
      // Arrange
      let request_path = "/status/404"

      // Act
      let segments = path.segments(request_path)

      // Assert
      segments
      |> should
      |> be_equal(["status", "404"])
      |> or_fail_with("Expected two segments")
    }),
    it("leaves out empty segments", fn() {
      // Arrange
      let request_path = "//status//404/"

      // Act
      let segments = path.segments(request_path)

      // Assert
      segments
      |> should
      |> be_equal(["status", "404"])
      |> or_fail_with("Expected two segments without the empty ones")
    }),
    it("gives no segments for the root path", fn() {
      // Arrange
      let request_path = "/"

      // Act
      let segments = path.segments(request_path)

      // Assert
      segments
      |> should
      |> be_equal([])
      |> or_fail_with("Expected no segments")
    }),
  ])
}

fn strip_extension_tests() {
  group("strip_extension", [
    it("removes one file extension", fn() {
      // Arrange
      let segment = "text.json"

      // Act
      let base = path.strip_extension(segment)

      // Assert
      base
      |> should
      |> be_equal("text")
      |> or_fail_with("Expected the part before the dot")
    }),
    it("keeps a segment without a dot", fn() {
      // Arrange
      let segment = "text"

      // Act
      let base = path.strip_extension(segment)

      // Assert
      base
      |> should
      |> be_equal("text")
      |> or_fail_with("Expected the same segment")
    }),
    it("keeps a segment with two dots", fn() {
      // Arrange
      let segment = "a.b.c"

      // Act
      let base = path.strip_extension(segment)

      // Assert
      base
      |> should
      |> be_equal("a.b.c")
      |> or_fail_with("Expected the same segment")
    }),
  ])
}
