import dream_mock_server/internal/built_in_endpoints
import dream_mock_server/views/index_view
import dream_test/matchers.{be_equal, match_snapshot, or_fail_with, should}
import dream_test/suite.{type TestSuite}
import dream_test/unit.{describe, group, it}
import gleam/list
import gleam/string

pub fn tests() -> TestSuite {
  describe("dream_mock_server/views/index_view", [
    group("format_index", [
      it("returns the endpoint documentation page", fn() {
        // Act
        let page = index_view.format_index()

        // Assert
        page
        |> should
        |> match_snapshot("test/snapshots/index_view_format_index.snap")
        |> or_fail_with("Expected the index page of the snapshot")
      }),
      it("names every entry of the built-in endpoint table", fn() {
        // Arrange
        let page_lines = string.split(index_view.format_index(), "\n")

        // Act
        let missing_lines =
          built_in_endpoints.table()
          |> list.map(built_in_endpoints.request_line)
          |> list.filter(fn(request_line) {
            !list.contains(page_lines, "  " <> request_line)
          })

        // Assert
        missing_lines
        |> should
        |> be_equal([])
        |> or_fail_with("Expected a line on the page for each endpoint")
      }),
      it("says that /stream/error sends status 500 before its chunks", fn() {
        // Arrange
        let page = index_view.format_index()

        // Act
        let has_line =
          string.contains(
            page,
            "  GET /stream/error\n    Status 500 first, then 3 chunks, one each 100 ms\n",
          )

        // Assert
        has_line
        |> should
        |> be_equal(True)
        |> or_fail_with("Expected status 500 before the chunks")
      }),
      it("names no fixed port", fn() {
        // Arrange
        let page = index_view.format_index()

        // Act
        let has_fixed_port = string.contains(page, "localhost:3004")

        // Assert
        has_fixed_port
        |> should
        |> be_equal(False)
        |> or_fail_with("Expected no fixed port on the page")
      }),
    ]),
  ])
}
