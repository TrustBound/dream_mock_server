import dream_mock_server/views/index_view
import dream_test/matchers.{match_snapshot, or_fail_with, should}
import dream_test/types.{type TestSuite}
import dream_test/unit.{describe, group, it}

pub fn tests() -> TestSuite(Nil) {
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
    ]),
  ])
}
